import AVFoundation
import UIKit

public enum CameraSide: String, Sendable {
    case back
    case front
}

public enum CameraFlashMode: String, Sendable {
    case off
    case on
}

/// Thin wrapper over an `AVCaptureSession`. On a device it drives the back
/// camera and captures a still; on the Simulator (no camera) it hands back a
/// synthetic `FilmScene` so the whole flow stays exercisable. Shared by the app
/// and the lock-screen capture extension.
@MainActor
public final class CameraController: NSObject, ObservableObject {
    public let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureHandler: ((UIImage) -> Void)?
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

    private let sessionQueue = DispatchQueue(label: "com.tumble.camera.session")
    private var configured = false

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

        guard
            session.canAddOutput(photoOutput)
        else {
            isSimulated = true
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo
        session.addOutput(photoOutput)
        guard configureInput(for: .back) else {
            session.commitConfiguration()
            isSimulated = true
            return
        }
        session.commitConfiguration()
    }

    public func switchCamera() {
        configureIfNeeded()
        guard canSwitchCameras, !isSimulated else { return }
        let next: CameraSide = side == .back ? .front : .back

        session.beginConfiguration()
        let switched = configureInput(for: next)
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

    private func device(for side: CameraSide) -> AVCaptureDevice? {
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: side == .back ? .back : .front
        )
    }

    /// Capture a still. Delivers a `UIImage` on the main actor.
    public func capture(_ completion: @escaping (UIImage) -> Void) {
        if isSimulated {
            completion(FilmScene.random().image())
            return
        }
        captureHandler = completion
        let settings = AVCapturePhotoSettings()
        if supportsFlash {
            settings.flashMode = flashMode == .on ? .on : .off
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
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
            if let image { self.captureHandler?(image) }
            self.captureHandler = nil
        }
    }
}
