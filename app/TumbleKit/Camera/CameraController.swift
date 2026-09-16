import AVFoundation
import UIKit

public struct CapturedPhoto: @unchecked Sendable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public var image: UIImage? { UIImage(data: data) }
}

public enum CameraSide: String, Sendable {
    case back
    case front
}

public enum CameraFlashMode: String, Sendable {
    case off
    case on
}

public enum CameraCaptureResult: @unchecked Sendable {
    case success(CapturedPhoto)
    case unavailable(String)
    case failure(String, Error?)
}

private struct CameraHardwareState: Sendable {
    var isSimulated: Bool
    var side: CameraSide
    var canSwitchCameras: Bool
    var supportsFlash: Bool
    var flashMode: CameraFlashMode
}

private final class MainActorCaptureCompletion: @unchecked Sendable {
    let call: (CameraCaptureResult) -> Void

    init(_ call: @escaping (CameraCaptureResult) -> Void) {
        self.call = call
    }
}

/// Owns every blocking AVFoundation operation on one serial executor. Nothing
/// in this type is isolated to the main actor; it reports compact state changes
/// back to the UI only after the hardware operation completes.
private final class CameraPipeline: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()
    let previewRenderer: LiveCameraRenderer

    var stateHandler: (@Sendable (CameraHardwareState) -> Void)?

    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.tumble.camera.session", qos: .userInitiated)
    private var captureHandler: (@Sendable (CameraCaptureResult) -> Void)?
    private var currentInput: AVCaptureDeviceInput?
    private var currentDevice: AVCaptureDevice?
    private var configured = false
    private var isSimulated = false
    private var side: CameraSide = .back
    private var canSwitchCameras = false
    private var supportsFlash = false
    private var flashMode: CameraFlashMode = .off
    private var requestedFrameRate = 60

    init(previewRenderer: LiveCameraRenderer) {
        self.previewRenderer = previewRenderer
        super.init()
        previewRenderer.onTargetFrameRateChanged = { [weak self] fps in
            self?.setFrameRate(fps)
        }
    }

    func start() {
        queue.async { [self] in
            configureIfNeeded()
            guard !isSimulated, !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stop() {
        queue.async { [self] in
            guard !isSimulated, session.isRunning else { return }
            session.stopRunning()
        }
    }

    func switchCamera() {
        queue.async { [self] in
            configureIfNeeded()
            guard canSwitchCameras, !isSimulated else { return }
            let next: CameraSide = side == .back ? .front : .back
            session.beginConfiguration()
            let switched = configureInput(for: next)
            if switched { configurePortraitOutput() }
            session.commitConfiguration()
            if switched {
                applyFrameRate(requestedFrameRate)
                publishState()
            }
        }
    }

    func setFlashMode(_ mode: CameraFlashMode) {
        queue.async { [self] in
            guard supportsFlash, !isSimulated else { return }
            flashMode = mode
            publishState()
        }
    }

    func capture(completion: @escaping @Sendable (CameraCaptureResult) -> Void) {
        queue.async { [self] in
            configureIfNeeded()
            guard !isSimulated else {
#if DEBUG && targetEnvironment(simulator)
                let data = FilmScene.random().image().jpegData(compressionQuality: 0.94)
                if let data { completion(.success(CapturedPhoto(data: data))) }
                else { completion(.failure("The simulated photo could not be encoded.", nil)) }
#else
                completion(.unavailable("The camera is unavailable."))
#endif
                return
            }
            guard captureHandler == nil else { return }
            captureHandler = completion
            let settings: AVCapturePhotoSettings
            if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                settings = AVCapturePhotoSettings()
            }
            settings.photoQualityPrioritization = .balanced
            if supportsFlash { settings.flashMode = flashMode == .on ? .on : .off }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        canSwitchCameras = device(for: .back) != nil && device(for: .front) != nil

        guard session.canAddOutput(photoOutput), session.canAddOutput(videoOutput) else {
            isSimulated = true
            publishState()
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo
        session.addOutput(photoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let biPlanarFullRange = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        let previewPixelFormat = videoOutput.availableVideoPixelFormatTypes.contains(biPlanarFullRange)
            ? biPlanarFullRange
            : kCVPixelFormatType_32BGRA
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelFormat,
        ]
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        session.addOutput(videoOutput)
        guard configureInput(for: .back) else {
            session.commitConfiguration()
            isSimulated = true
            publishState()
            return
        }
        configurePortraitOutput()
        session.commitConfiguration()
        applyFrameRate(requestedFrameRate)
        publishState()
    }

    private func configureInput(for side: CameraSide) -> Bool {
        guard let device = device(for: side),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }

        let previousInput = currentInput
        if let previousInput { session.removeInput(previousInput) }
        guard session.canAddInput(input) else {
            if let previousInput, session.canAddInput(previousInput) { session.addInput(previousInput) }
            return false
        }

        session.addInput(input)
        currentInput = input
        currentDevice = device
        self.side = side
        supportsFlash = side == .back && device.hasFlash
        if !supportsFlash { flashMode = .off }
        return true
    }

    private func configurePortraitOutput() {
        for connection in [
            videoOutput.connection(with: .video),
            photoOutput.connection(with: .video),
        ].compactMap({ $0 }) where connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    private func device(for side: CameraSide) -> AVCaptureDevice? {
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: side == .back ? .back : .front
        )
    }

    private func setFrameRate(_ fps: Int) {
        queue.async { [self] in
            requestedFrameRate = fps == 30 ? 30 : 60
            applyFrameRate(requestedFrameRate)
        }
    }

    private func applyFrameRate(_ requested: Int) {
        guard let device = currentDevice else { return }
        let supported = device.activeFormat.videoSupportedFrameRateRanges.contains {
            $0.minFrameRate <= Double(requested) && $0.maxFrameRate >= Double(requested)
        }
        let fallback = device.activeFormat.videoSupportedFrameRateRanges.contains {
            $0.minFrameRate <= 30 && $0.maxFrameRate >= 30
        }
        let actual = supported ? requested : (fallback ? 30 : 0)
        guard actual > 0, (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        let duration = CMTime(value: 1, timescale: CMTimeScale(actual))
        device.activeVideoMinFrameDuration = duration
        device.activeVideoMaxFrameDuration = duration
    }

    private func publishState() {
        stateHandler?(CameraHardwareState(
            isSimulated: isSimulated,
            side: side,
            canSwitchCameras: canSwitchCameras,
            supportsFlash: supportsFlash,
            flashMode: flashMode
        ))
    }
}

extension CameraPipeline: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let completion = captureHandler
        captureHandler = nil
        if let error {
            completion?(.failure("The camera could not take that photo.", error))
        } else if let data = photo.fileDataRepresentation() {
            completion?(.success(CapturedPhoto(data: data)))
        } else {
            completion?(.failure("The captured photo could not be prepared.", nil))
        }
    }
}

extension CameraPipeline: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        previewRenderer.enqueue(pixelBuffer)
    }
}

/// Main-actor facade used by SwiftUI. The AVFoundation and Metal work lives in
/// `CameraPipeline`; published properties change only for controls and never
/// once per camera frame.
@MainActor
public final class CameraController: NSObject, ObservableObject {
    public let session: AVCaptureSession
    public let previewRenderer: LiveCameraRenderer

    @Published public private(set) var isSimulated = false
    @Published public private(set) var side: CameraSide = .back
    @Published public private(set) var canSwitchCameras = false
    @Published public private(set) var supportsFlash = false
    @Published public private(set) var flashMode: CameraFlashMode = .off

    public var previewStock: FilmStock = FilmStockCatalog.defaultStock {
        didSet { updatePreviewRecipe() }
    }
    public var previewIntensity: Double = 1 {
        didSet { updatePreviewRecipe() }
    }

    private let pipeline: CameraPipeline

    public override init() {
        let renderer = LiveCameraRenderer()
        let pipeline = CameraPipeline(previewRenderer: renderer)
        previewRenderer = renderer
        session = pipeline.session
        self.pipeline = pipeline
        super.init()
        pipeline.stateHandler = { [weak self] state in
            Task { @MainActor [weak self] in self?.apply(state) }
        }
        updatePreviewRecipe()
    }

    public func start() { pipeline.start() }
    public func stop() { pipeline.stop() }

    public func switchCamera() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pipeline.switchCamera()
    }

    public func toggleFlash() {
        guard supportsFlash, !isSimulated else { return }
        let next: CameraFlashMode = flashMode == .off ? .on : .off
        flashMode = next
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pipeline.setFlashMode(next)
    }

    public func captureResult(_ completion: @escaping (CameraCaptureResult) -> Void) {
        let callback = MainActorCaptureCompletion(completion)
        pipeline.capture { result in
            Task { @MainActor in callback.call(result) }
        }
    }

    /// Compatibility for onboarding and the older pull-down camera.
    public func capture(_ completion: @escaping (UIImage) -> Void) {
        captureResult { result in
            if case .success(let photo) = result, let image = photo.image { completion(image) }
        }
    }

    private func apply(_ state: CameraHardwareState) {
        isSimulated = state.isSimulated
        side = state.side
        canSwitchCameras = state.canSwitchCameras
        supportsFlash = state.supportsFlash
        flashMode = state.flashMode
        updatePreviewRecipe()
    }

    private func updatePreviewRecipe() {
        previewRenderer.update(
            stock: previewStock,
            intensity: previewIntensity,
            mirrored: side == .front
        )
    }
}
