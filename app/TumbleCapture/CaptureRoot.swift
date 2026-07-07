import SwiftUI
import SwiftData
import LockedCameraCapture
import TumbleKit

/// The capture UI shown on the Lock Screen. Reuses the shared viewfinder,
/// writes to the shared Drawer, and honors the same Roll - reading the tier the
/// app mirrored into the App Group (the extension has no StoreKit).
struct CaptureRoot: View {
    let session: LockedCameraCaptureSession

    @State private var container: ModelContainer? = try? PhotoStore.makeContainer()
    @State private var roll = RollManager(loadsEntitlementFromDefaults: true)
    @State private var flash = false

    var body: some View {
        ZStack {
            if let container {
                QuickCaptureView(roll: roll) { image in
                    capture(image, into: container)
                }
                .modelContainer(container)
            } else {
                GraincoreBackground()
            }
            Color.white.opacity(flash ? 0.85 : 0).ignoresSafeArea()
        }
    }

    private func capture(_ image: UIImage, into container: ModelContainer) {
        withAnimation(.easeOut(duration: 0.08)) { flash = true }
        withAnimation(.easeIn(duration: 0.25).delay(0.08)) { flash = false }
        CaptureService.store(rawImage: image, source: .lockscreen, roll: roll, in: container.mainContext)
    }
}
