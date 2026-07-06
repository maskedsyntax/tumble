import SwiftUI
import LockedCameraCapture

/// The lock-screen camera. iOS launches this `LockedCameraCaptureExtension`
/// from the Control (see TumbleControls) even while the device is locked. Shots
/// land in the shared App Group Drawer and spend from the same Roll; the app
/// reconciles them on next unlock.
@main
struct TumbleCaptureExtension: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            CaptureRoot(session: session)
        }
    }
}
