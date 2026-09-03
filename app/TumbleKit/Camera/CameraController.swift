import AVFoundation
import CoreImage
import QuartzCore
import UIKit

private struct SendablePixelBuffer: @unchecked Sendable {
    let value: CVPixelBuffer
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
    case success(UIImage)
    case unavailable(String)
    case failure(String, Error?)
}

/// Thin wrapper over an `AVCaptureSession`. Production always returns an
/// explicit success, unavailable, or failure result. A synthetic scene is
/// available only in a DEBUG simulator build so the Studio remains testable.
@MainActor
public final class CameraController: NSObject, ObservableObject {
    public let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var captureHandler: ((CameraCaptureResult) -> Void)?
    private var currentInput: AVCaptureDeviceInput?
    private var currentDevice: AVCaptureDevice?

    public override init() { super.init() }

    /// True when there is no usable camera (Simulator / denied), so the UI can
    /// show a filmic placeholder instead of a black viewfinder.
    @Published public private(set) var isSimulated = false
    @Published public private(set) var side: CameraSide = .back
    @Published public private(set) var canSwitchCameras = false
    @Published public private(set) var supportsFlash = false
    @Published public private(set) var flashMode: CameraFlashMode = .off
    @Published public private(set) var filteredPreview: UIImage?
    @Published public var previewStock: FilmStock = FilmStockCatalog.defaultStock
    @Published public var previewIntensity: Double = 1

    private let sessionQueue = DispatchQueue(label: "com.tumble.camera.session")
    private var configured = false
    private var previewRenderInFlight = false
    nonisolated(unsafe) private var lastPreviewTimestamp: CFTimeInterval = 0

    public func start() {
        configureIfNeeded()
        guard !isSimulated else { return }
        nonisolated(unsafe) let session = self.session
        sessionQueue.async {
            if !session.isRunning { session.startRunning() }
        }
    }

    public func stop() {
        guard !isSimulated else { return }
        nonisolated(unsafe) let session = self.session
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        canSwitchCameras = device(for: .back) != nil && device(for: .front) != nil

        guard session.canAddOutput(photoOutput), session.canAddOutput(videoOutput) else {
            isSimulated = true
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo
        session.addOutput(photoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        session.addOutput(videoOutput)
        guard configureInput(for: .back) else {
            session.commitConfiguration()
            isSimulated = true
            return
        }
        configurePortraitOutput()
        session.commitConfiguration()
    }

    public func switchCamera() {
        configureIfNeeded()
        guard canSwitchCameras, !isSimulated else { return }
        let next: CameraSide = side == .back ? .front : .back

        session.beginConfiguration()
        let switched = configureInput(for: next)
        if switched { configurePortraitOutput() }
        session.commitConfiguration()

        if switched {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    public func toggleFlash() {
        configureIfNeeded()
        guard supportsFlash, !isSimulated else { return }
        flashMode = flashMode == .off ? .on : .off
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func configureInput(for side: CameraSide) -> Bool {
        guard
            let device = device(for: side),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            return false
        }

        let previousInput = currentInput
        if let previousInput {
            session.removeInput(previousInput)
        }

        guard session.canAddInput(input) else {
            if let previousInput, session.canAddInput(previousInput) {
                session.addInput(previousInput)
            }
            return false
        }

        session.addInput(input)
        currentInput = input
        currentDevice = device
        self.side = side
        supportsFlash = side == .back && device.hasFlash
        if !supportsFlash {
            flashMode = .off
        }
        return true
    }

    /// Tumble is portrait-only. Camera sensors deliver their native buffers in
    /// landscape, so rotate both the live effect buffer and the still output at
    /// the capture boundary rather than making each UI compensate separately.
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

    /// Capture a still with an explicit production-safe outcome.
    public func captureResult(_ completion: @escaping (CameraCaptureResult) -> Void) {
        if isSimulated {
#if DEBUG
#if targetEnvironment(simulator)
            completion(.success(FilmScene.random().image()))
#else
            completion(.unavailable("The camera is unavailable."))
#endif
#else
            completion(.unavailable("The camera is unavailable."))
#endif
            return
        }
        captureHandler = completion
        let settings = AVCapturePhotoSettings()
        if supportsFlash {
            settings.flashMode = flashMode == .on ? .on : .off
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// Compatibility for legacy screens while they remain available from the
    /// read-only Drawer. New code must use `captureResult`.
    public func capture(_ completion: @escaping (UIImage) -> Void) {
        captureResult { result in
            if case .success(let image) = result { completion(image) }
        }
    }

    private func renderPreview(_ pixelBuffer: CVPixelBuffer) async {
        guard !previewRenderInFlight else { return }
        previewRenderInFlight = true
        defer { previewRenderInFlight = false }
        let input = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        let stock = previewStock
        let intensity = previewIntensity
        filteredPreview = await Task.detached(priority: .userInitiated) {
            TumblePhotoFilter.renderLivePreview(
                from: input,
                stock: stock,
                intensity: intensity,
                maxDimension: 960
            )
        }.value
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    public nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            if let error {
                self.captureHandler?(.failure("The camera could not take that photo.", error))
            } else if let image {
                self.captureHandler?(.success(image))
            } else {
                self.captureHandler?(.failure("The captured photo could not be decoded.", nil))
            }
            self.captureHandler = nil
        }
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        guard now - lastPreviewTimestamp >= 0.10,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastPreviewTimestamp = now
        let buffer = SendablePixelBuffer(value: pixelBuffer)
        Task { @MainActor [weak self, buffer] in await self?.renderPreview(buffer.value) }
    }
}
