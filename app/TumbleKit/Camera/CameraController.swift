import AVFoundation
import UIKit

/// Thin wrapper over an `AVCaptureSession`. On a device it drives the back
/// camera and captures a still; on the Simulator (no camera) it hands back a
/// synthetic `FilmScene` so the whole flow stays exercisable. Shared by the app
/// and the lock-screen capture extension.
@MainActor
public final class CameraController: NSObject, ObservableObject {
    public let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureHandler: ((UIImage) -> Void)?

    public override init() { super.init() }

    /// True when there is no usable camera (Simulator / denied), so the UI can
    /// show a filmic placeholder instead of a black viewfinder.
    @Published public private(set) var isSimulated = false

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

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(photoOutput)
        else {
            isSimulated = true
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
    }

    /// Capture a still. Delivers a `UIImage` on the main actor.
    public func capture(_ completion: @escaping (UIImage) -> Void) {
        if isSimulated {
            completion(FilmScene.random().image())
            return
        }
        captureHandler = completion
        let settings = AVCapturePhotoSettings()
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
