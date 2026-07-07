import SwiftUI
import TumbleKit

/// First-run onboarding - a clean, dedicated screen (not an overlay on the
/// Drawer). A looping animation shows the camera stretching down out of the
/// Dynamic Island so the shooter knows where it lives; "Got it" enters the app.
struct OnboardingScreen: View {
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            GraincoreBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                PullDownDemo()
                    .frame(height: 300)

                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    Text("Your camera lives up top").kicker()
                    Text("Pull it down to shoot")
                        .font(Typography.display(30))
                        .foregroundStyle(Palette.cream)
                        .multilineTextAlignment(.center)
                    Text("Twelve shots a day. Shake each one to develop -\nthen it lands in your Drawer.")
                        .font(Typography.sans(15))
                        .foregroundStyle(Palette.cream.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 24)

                Button(action: onDone) {
                    Text("Got it")
                        .font(Typography.sans(16, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Palette.amber, in: Capsule())
                        .shadow(color: Palette.amber.opacity(0.3), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.bottom, 44)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
        }
        .task { withAnimation(.easeOut(duration: 0.5)) { appeared = true } }
    }
}

/// The looping demo: a black island pill that smoothly stretches into a camera
/// window and retracts, with a touch ring dragging its lower edge down.
private struct PullDownDemo: View {
    private let closedW: CGFloat = 118
    private let closedH: CGFloat = 34
    private let closedR: CGFloat = 17
    private let openW: CGFloat = 210
    private let openH: CGFloat = 232
    private let openR: CGFloat = 40

    var body: some View {
        PhaseAnimator([0.0, 1.0]) { progress in
            frameContent(progress)
        } animation: { _ in
            .easeInOut(duration: 1.5)
        }
        .frame(width: 240, height: 300)
    }

    @ViewBuilder private func frameContent(_ p: CGFloat) -> some View {
        let w = lerp(closedW, openW, p)
        let h = lerp(closedH, openH, p)
        let r = lerp(closedR, openR, p)

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(.black)
                .frame(width: w, height: h)
                .overlay(
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(Palette.amber.opacity(0.25 + 0.35 * p), lineWidth: 1.2)
                )
                .overlay(
                    preview(p)
                        .frame(width: w, height: h)
                        .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
                )
                .shadow(color: .black.opacity(0.4 * p), radius: 20 * p, y: 10 * p)
                .shadow(color: Palette.amber.opacity(0.18 * p), radius: 26 * p, y: 8 * p)
                .position(x: 120, y: h / 2)

            // Touch ring dragging the window's lower edge down.
            touchRing
                .position(x: 120, y: h + 24)
        }
    }

    private func preview(_ p: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A3A49), Color(hex: 0x172330)],
                           startPoint: .top, endPoint: .bottom)
            GrainOverlay(opacity: 0.22)
            Image(systemName: "camera.aperture")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.85))
        }
        .opacity(smoothstep(p, 0.2, 0.75))
    }

    private var touchRing: some View {
        ZStack {
            Circle().strokeBorder(Palette.cream.opacity(0.35), lineWidth: 7).frame(width: 46, height: 46)
            Circle().fill(Palette.cream.opacity(0.9)).frame(width: 26, height: 26)
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink.opacity(0.7))
        }
    }
}

// MARK: - Local interpolation helpers

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

private func smoothstep(_ x: CGFloat, _ edge0: CGFloat, _ edge1: CGFloat) -> CGFloat {
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}
