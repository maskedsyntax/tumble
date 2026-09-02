import SwiftUI
import TumbleKit

struct TumbleThreeOnboarding: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 22) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Palette.charcoalDeep.opacity(0.78))
                        .frame(width: 230, height: 280)
                        .rotationEffect(.degrees(-6))
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(Palette.gold)
                }
                .shadow(color: .black.opacity(0.35), radius: 24, y: 14)

                Text("Tumble")
                    .font(Typography.display(40))
                    .foregroundStyle(Palette.cream)
                Text("Your private film camera.")
                    .font(Typography.display(27))
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.center)
                Text("Shoot something new or bring a photo with you. Choose a film, make it yours, and save it—without sending your pictures anywhere.")
                    .font(Typography.sans(15))
                    .foregroundStyle(Palette.cream.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)

                Label("No account · Local photo processing", systemImage: "lock.shield")
                    .font(Typography.sans(12, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.58))
                Spacer()
                Button(action: onDone) {
                    Label("Open the camera", systemImage: "arrow.right")
                        .font(Typography.sans(16, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Palette.gold, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }
}
