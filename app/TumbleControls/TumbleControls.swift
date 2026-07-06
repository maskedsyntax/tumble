import WidgetKit
import SwiftUI
import AppIntents

/// The Lock Screen / Control Center control that launches Tumble's camera.
/// On a provisioned device this is what surfaces the "tiny lock-screen camera."
@main
struct TumbleControlsBundle: WidgetBundle {
    var body: some Widget {
        TumbleCameraControl()
    }
}

struct TumbleCameraControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.tumble.control.camera") {
            ControlWidgetButton(action: LaunchTumbleIntent()) {
                Label("Tumble", systemImage: "camera.aperture")
            }
        }
        .displayName("Tumble Camera")
        .description("Open Tumble and take one of your twelve.")
    }
}

/// Opens the app to the camera. (Capturing while still locked is handled by the
/// LockedCameraCapture extension; wiring this button directly to that extension
/// via a CameraCaptureIntent is the device-side finalization step.)
struct LaunchTumbleIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Tumble"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
