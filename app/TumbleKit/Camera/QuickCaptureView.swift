import SwiftUI

/// A compact viewfinder + shutter used by the lock-screen capture extension
/// (and reusable anywhere a minimal camera is wanted). Reports the captured
/// frame via `onCapture`. Honors the Roll: when empty it shows the calm
/// "fresh at sunrise" state instead of a shutter.
public struct QuickCaptureView: View {
    @StateObject private var camera = CameraController()
    private let roll: RollManager
    private let onCapture: (UIImage) -> Void

    public init(roll: RollManager, onCapture: @escaping (UIImage) -> Void) {
        self.roll = roll
        self.onCapture = onCapture
    }

    public var body: some View {
        ZStack {
            if camera.isSimulated {
                GraincoreBackground()
            } else {
                CameraPreview(session: camera.session).ignoresSafeArea()
            }
            GrainOverlay(opacity: 0.14)

            VStack {
                HStack {
                    Text(roll.remainingLabel)
                        .font(Typography.sans(13, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.black.opacity(0.28), in: Capsule())
                    Spacer()
                }
                Spacer()
                shutterOrEmpty
            }
            .padding(20)
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }

    @ViewBuilder private var shutterOrEmpty: some View {
        if roll.canShoot {
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                camera.capture(onCapture)
            } label: {
                ZStack {
                    Circle().strokeBorder(Palette.cream.opacity(0.9), lineWidth: 4).frame(width: 74, height: 74)
                    Circle().fill(Palette.cream).frame(width: 60, height: 60)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take a shot")
        } else {
            VStack(spacing: 4) {
                Text("That's the roll for today.")
                    .font(Typography.display(19)).foregroundStyle(Palette.cream)
                Text("Fresh twelve at sunrise.")
                    .font(Typography.sans(13)).foregroundStyle(Palette.cream.opacity(0.7))
            }
            .padding(.bottom, 8)
        }
    }
}
