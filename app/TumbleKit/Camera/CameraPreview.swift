import SwiftUI
import AVFoundation

/// Live viewfinder backed by `AVCaptureVideoPreviewLayer`.
public struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    public init(session: AVCaptureSession) { self.session = session }

    public func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: PreviewView, context: Context) {}

    public final class PreviewView: UIView {
        public override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
