import SwiftUI
import SwiftData
import TumbleKit

/// The camera as a window you pull *out of* the Dynamic Island.
///
/// At rest it's a black pill sitting where the island is. Drag down and it
/// stretches into a live camera window — geometry tracks your finger, so it
/// feels physically tethered to the island. Release past the threshold and it
/// springs open; shoot, and the print drops into the Drawer as the window
/// retracts back into the island.
struct IslandCamera: View {
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var app
    @StateObject private var camera = CameraController()

    let screenWidth: CGFloat
    let topInset: CGFloat
    /// Whether this device has a Dynamic Island. When true the closed handle
    /// merges with the hardware island; when false it renders as a clean,
    /// visible floating handle just below the notch/status bar.
    var hasIsland: Bool = true
    /// Called after a shot lands, so the home can react (e.g. counters).
    var onCaptured: () -> Void = {}
    /// Called when an empty roll wants to send the shooter to the paywall.
    var onNeedMore: () -> Void = {}
    /// Debug: open the window on appear (for previews / screenshots).
    var autoOpen: Bool = false

    // Progress 0 (pill) → 1 (open window).
    @State private var progress: CGFloat = 0
    @State private var opened = false
    @State private var cameraLive = false
    @State private var flash = false

    // MARK: Geometry

    // Closed pill matches the physical Dynamic Island footprint.
    private let closedW: CGFloat = 126
    private let closedH: CGFloat = 37
    private let closedCorner: CGFloat = 19

    /// Where the window's top edge sits at rest: over the island on DI phones,
    /// just below the notch/status bar otherwise (so the notch never lands
    /// inside the black window).
    private var anchorTopY: CGFloat { hasIsland ? 11 : topInset + 4 }

    private var openW: CGFloat { min(screenWidth - 40, 330) }
    private var previewH: CGFloat { openW * 0.86 }
    private var openH: CGFloat { previewH + 96 }
    private var openCorner: CGFloat { 42 }
    private var openDistance: CGFloat { openH - closedH }

    private var w: CGFloat { lerp(closedW, openW, progress) }
    private var h: CGFloat { lerp(closedH, openH, progress) }
    private var corner: CGFloat { lerp(closedCorner, openCorner, progress) }
    private var contentOpacity: CGFloat { smoothstep(progress, 0.06, 0.42) }
    private var controlsOpacity: CGFloat { smoothstep(progress, 0.55, 1) }

    // On DI phones the closed pill blends with the hardware (no rim/shadow at
    // rest). On other phones it needs a visible rim and lift so it reads as a
    // deliberate pull-down handle rather than a stray black pill.
    private var handleBorderOpacity: CGFloat { hasIsland ? progress * 0.35 : max(0.5, progress * 0.35) }
    private var handleShadowOpacity: CGFloat { hasIsland ? 0.4 * progress : max(0.28, 0.4 * progress) }
    private var handleShadowRadius: CGFloat { hasIsland ? 22 * progress : max(10, 22 * progress) }
    private var handleShadowY: CGFloat { hasIsland ? 12 * progress : max(5, 12 * progress) }

    var body: some View {
        ZStack(alignment: .top) {
            // Dim the home behind the window; tap outside to close.
            if progress > 0.01 {
                Color.black.opacity(progress * 0.55)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
            }

            window
                .position(x: screenWidth / 2, y: anchorTopY + h / 2)

            // On DI phones the closed pill hides behind the hardware island, so
            // show an informational chip below it. On other phones the handle
            // itself is visible, so this chip would be redundant.
            if hasIsland && progress < 0.35 {
                pullTab
                    .position(x: screenWidth / 2, y: topInset + 8)
                    .opacity(1 - smoothstep(progress, 0, 0.3))
                    .allowsHitTesting(false)
            }

            // Drag the island / handle down to grow the camera window.
            islandGrabber
        }
        .onAppear {
            if autoOpen { open() }
            // Debug: freeze a mid-stretch state to inspect the island morph.
            if ProcessInfo.processInfo.arguments.contains("-islandHalf") {
                startCameraIfNeeded()
                progress = 0.5
            }
        }
        .onDisappear { camera.stop() }
    }

    /// Invisible catcher over the physical island (and a comfortable margin
    /// around/below it) so the island itself is the drag handle — grab it and
    /// pull down and it swells into the camera window. A tap opens too, but drag
    /// is the primary gesture; there is no separate button to press.
    private var islandGrabber: some View {
        let height = topInset + 48
        return Rectangle()
            .fill(Color.clear)
            .frame(width: max(closedW + 150, 250), height: height)
            .contentShape(Rectangle())
            .position(x: screenWidth / 2, y: height / 2)
            .gesture(dragGesture)
            .onTapGesture { if !opened { open() } }
            .allowsHitTesting(!opened)
            .accessibilityElement()
            .accessibilityLabel(
                opened
                    ? "Camera open"
                    : (hasIsland
                        ? "Pull down the Dynamic Island for the camera. \(app.roll.remainingLabel)."
                        : "Pull down for the camera. \(app.roll.remainingLabel).")
            )
            .accessibilityAddTraits(.isButton)
    }

    private var pullTab: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.amber)
            Text(app.roll.remainingLabel)
                .font(Typography.sans(11, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.9))
                .lineLimit(1)
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.cream.opacity(0.7))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 5)
        .background(.black.opacity(0.55), in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        .accessibilityElement()
        .accessibilityLabel("Pull down for the camera. \(app.roll.remainingLabel).")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Window

    private var window: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Palette.amber.opacity(handleBorderOpacity), lineWidth: hasIsland ? 1 : 1.25)
                )
                .shadow(color: .black.opacity(handleShadowOpacity), radius: handleShadowRadius, y: handleShadowY)
                .shadow(color: Palette.amber.opacity(0.16 * progress), radius: 30 * progress, y: 10 * progress)

            // Open-state content, laid out at full size and revealed top-down as
            // the window grows — the "pulled from the island" reveal.
            openContent
                .frame(width: openW, height: openH, alignment: .top)
                .frame(width: w, height: h, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .opacity(contentOpacity)

            // Flash on capture.
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.white)
                .opacity(flash ? 0.9 : 0)

            // Closed pill hint (grab affordance) fades out as it opens.
            pillHint.opacity(1 - smoothstep(progress, 0, 0.25))
        }
        .frame(width: w, height: h)
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .gesture(dragGesture)
        .onTapGesture { if !opened { open() } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(opened ? "Camera window. Take a shot." : "Pull down for the camera")
    }

    private var pillHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.amber)
            Text(app.roll.remainingLabel)
                .font(Typography.sans(11, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.85))
                .lineLimit(1).minimumScaleFactor(0.7)
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.cream.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .frame(height: closedH)
    }

    // MARK: Open content (preview + controls)

    private var openContent: some View {
        VStack(spacing: 0) {
            preview
                .frame(width: openW - 16, height: previewH)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.top, 8)

            controls
                .opacity(controlsOpacity)
                .padding(.top, 10)

            Spacer(minLength: 0)
        }
        .frame(width: openW, height: openH, alignment: .top)
    }

    @ViewBuilder private var preview: some View {
        if camera.isSimulated {
            ZStack {
                GraincoreBackground()
                GrainOverlay(opacity: 0.2)
                Image(systemName: "camera.aperture")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.8))
            }
        } else {
            CameraPreview(session: camera.session)
        }
    }

    @ViewBuilder private var controls: some View {
        if app.roll.canShoot {
            HStack(spacing: 28) {
                Text(app.roll.remainingLabel)
                    .font(Typography.sans(12, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.85))
                    .frame(width: 64, alignment: .leading)

                Button(action: capture) {
                    ZStack {
                        Circle().strokeBorder(Palette.cream.opacity(0.9), lineWidth: 3)
                            .frame(width: 54, height: 54)
                        Circle().fill(Palette.cream)
                            .frame(width: 42, height: 42)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!opened)
                .accessibilityLabel("Take a shot")

                closeChevron.frame(width: 64, alignment: .trailing)
            }
            .padding(.horizontal, 18)
        } else {
            // Empty roll: calm "fresh at sunrise" state with a path to own more.
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("That's the roll for today.")
                        .font(Typography.sans(13, weight: .semibold)).foregroundStyle(Palette.cream)
                    Text("Fresh twelve at sunrise.")
                        .font(Typography.sans(11)).foregroundStyle(Palette.cream.opacity(0.6))
                }
                Spacer(minLength: 6)
                Button { close(); onNeedMore() } label: {
                    Text("Own more")
                        .font(Typography.sans(13, weight: .bold)).foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Palette.gold, in: Capsule())
                }
                .buttonStyle(.plain)
                closeChevron
            }
            .padding(.horizontal, 16)
        }
    }

    private var closeChevron: some View {
        Button(action: close) {
            Image(systemName: "chevron.up")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.cream.opacity(0.8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close camera")
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                startCameraIfNeeded()
                let base: CGFloat = opened ? 1 : 0
                progress = clamp(base + value.translation.height / openDistance, 0, 1)
            }
            .onEnded { value in
                let projected = progress + value.predictedEndTranslation.height / openDistance / 3
                if projected > 0.42 { open() } else { close() }
            }
    }

    // MARK: Actions

    private func open() {
        startCameraIfNeeded()
        opened = true
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) { progress = 1 }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func close() {
        opened = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { progress = 0 }
        // Stop the session once it has fully retracted.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if !opened { camera.stop(); cameraLive = false }
        }
    }

    private func startCameraIfNeeded() {
        guard !cameraLive else { return }
        cameraLive = true
        camera.start()
    }

    private func capture() {
        guard app.roll.canShoot, opened else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        camera.capture { image in
            withAnimation(.easeOut(duration: 0.07)) { flash = true }
            withAnimation(.easeIn(duration: 0.22).delay(0.07)) { flash = false }
            if app.store(rawImage: image, in: context) {
                onCaptured()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                // Let the print land in the drawer, then retract into the island.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { close() }
            }
        }
    }
}

// MARK: - Interpolation helpers

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * clamp(t, 0, 1)
}

private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    min(max(v, lo), hi)
}

/// Smooth 0→1 ramp between `edge0` and `edge1` (Hermite).
private func smoothstep(_ x: CGFloat, _ edge0: CGFloat, _ edge1: CGFloat) -> CGFloat {
    let t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
}
