import StoreKit
import SwiftUI
import TumbleKit

/// First-run onboarding: a compact, non-scrolling walkthrough of the full
/// Tumble loop, ending with a one-time purchase moment.
struct OnboardingScreen: View {
    @Environment(AppModel.self) private var app
    let onDone: () -> Void

    @State private var page = 0
    @State private var appeared = false
    @State private var busy: String?

    private let pageCount = 4

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 720
            let bottomInset = max(geo.safeAreaInsets.bottom, 14)

            ZStack {
                GraincoreBackground()

                VStack(spacing: 0) {
                    brandBar
                        .padding(.top, geo.safeAreaInsets.top + (compact ? 10 : 18))
                        .padding(.horizontal, 22)

                    TabView(selection: $page) {
                        OnboardingPage(
                            kicker: "Shoot fast",
                            title: "The camera is always up top.",
                            message: "Pull down, flip front or back, turn on flash, and take the shot before the moment gets too polished.",
                            chips: ["Pull down", "Switch camera", "Flash"],
                            compact: compact
                        ) {
                            PullDownDemo(compact: compact)
                        }
                        .tag(0)

                        OnboardingPage(
                            kicker: "Make prints",
                            title: "Every shot becomes a print.",
                            message: "Photos land face-down in your Drawer. Shake to develop, or hold when motion is not available.",
                            chips: ["Drawer", "Shake to develop", "12 free daily"],
                            compact: compact
                        ) {
                            PrintFlowDemo(compact: compact)
                        }
                        .tag(1)

                        OnboardingPage(
                            kicker: "Own the Drawer",
                            title: "Arrange the mess your way.",
                            message: "Spread the pile, drag prints into new places, and reset the Drawer when you want it tidy again.",
                            chips: ["Pinch open", "Swap prints", "Reset layout"],
                            compact: compact
                        ) {
                            DrawerControlDemo(compact: compact)
                        }
                        .tag(2)

                        PremiumOnboardingPage(
                            compact: compact,
                            plusProduct: app.purchases.product(for: .plus),
                            unlimitedProduct: app.purchases.product(for: .unlimited),
                            busy: busy,
                            onBuy: buy,
                            onRestore: restore,
                            onStartFree: onDone
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: page)

                    bottomControls(compact: compact)
                        .padding(.horizontal, 22)
                        .padding(.bottom, bottomInset)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }
            .ignoresSafeArea()
        }
        .task {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            await app.startStore()
        }
    }

    private var brandBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 28, height: 28)
                    .background(Palette.gold, in: Circle())
                Text("Tumble")
                    .font(Typography.display(22))
                    .foregroundStyle(Palette.cream)
            }

            Spacer()

            Text("Pay once. No subscription.")
                .font(Typography.sans(11, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.62))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.22), in: Capsule())
        }
    }

    private func bottomControls(compact: Bool) -> some View {
        VStack(spacing: compact ? 10 : 14) {
            PageDots(count: pageCount, selection: page)

            if page < pageCount - 1 {
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        page += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(page == 0 ? "Show me the Drawer" : "Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(Typography.sans(16, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 12 : 15)
                    .background(Palette.gold, in: Capsule())
                    .shadow(color: Palette.gold.opacity(0.28), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continue onboarding")
            }
        }
    }

    @MainActor
    private func buy(_ tier: Entitlement) async {
        guard let product = app.purchases.product(for: tier), busy == nil else { return }
        busy = tier.productID
        defer { busy = nil }
        if await app.purchases.purchase(product) {
            app.syncEntitlement()
            onDone()
        }
    }

    @MainActor
    private func restore() async {
        guard busy == nil else { return }
        busy = "restore"
        defer { busy = nil }
        await app.purchases.restore()
        app.syncEntitlement()
        if app.purchases.entitlement > .free {
            onDone()
        }
    }
}

private struct OnboardingPage<Visual: View>: View {
    let kicker: String
    let title: String
    let message: String
    let chips: [String]
    let compact: Bool
    @ViewBuilder var visual: () -> Visual

    var body: some View {
        VStack(spacing: compact ? 12 : 18) {
            Spacer(minLength: compact ? 4 : 12)

            visual()
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 210 : 275)

            VStack(spacing: compact ? 7 : 9) {
                Text(kicker).kicker()
                Text(title)
                    .font(Typography.display(compact ? 27 : 32))
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                Text(message)
                    .font(Typography.sans(compact ? 13 : 15))
                    .foregroundStyle(Palette.cream.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)
            }

            FeatureChips(chips: chips, compact: compact)

            Spacer(minLength: compact ? 2 : 10)
        }
        .padding(.horizontal, 26)
    }
}

private struct PremiumOnboardingPage: View {
    let compact: Bool
    let plusProduct: Product?
    let unlimitedProduct: Product?
    let busy: String?
    let onBuy: (Entitlement) async -> Void
    let onRestore: () async -> Void
    let onStartFree: () -> Void

    var body: some View {
        VStack(spacing: compact ? 9 : 13) {
            Spacer(minLength: compact ? 2 : 8)

            KeepDemo(compact: compact)
                .frame(height: compact ? 108 : 140)

            VStack(spacing: compact ? 5 : 7) {
                Text("Keep what matters").kicker()
                Text("Start with the full camera.")
                    .font(Typography.display(compact ? 25 : 31))
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text("Collections, saving, and removing prints are included. Pay once when you want more daily shots.")
                    .font(Typography.sans(compact ? 12 : 14))
                    .foregroundStyle(Palette.cream.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
            }

            HStack(spacing: 8) {
                MiniPromise(icon: "folder", text: "Collections")
                MiniPromise(icon: "square.and.arrow.down", text: "Save")
                MiniPromise(icon: "trash", text: "Remove from Drawer")
            }

            VStack(spacing: compact ? 8 : 10) {
                PremiumChoiceCard(
                    tier: .plus,
                    product: plusProduct,
                    featured: true,
                    busy: busy == Entitlement.plus.productID,
                    onBuy: onBuy
                )

                PremiumChoiceCard(
                    tier: .unlimited,
                    product: unlimitedProduct,
                    featured: false,
                    busy: busy == Entitlement.unlimited.productID,
                    onBuy: onBuy
                )
            }

            HStack(spacing: 12) {
                Button(action: onStartFree) {
                    Text("Start with 12 free shots")
                        .font(Typography.sans(13, weight: .semibold))
                        .foregroundStyle(Palette.cream.opacity(0.82))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 9 : 11)
                        .background(.black.opacity(0.2), in: Capsule())
                        .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start with twelve free shots")

                Button { Task { await onRestore() } } label: {
                    ZStack {
                        if busy == "restore" {
                            ProgressView()
                                .tint(Palette.cream)
                                .controlSize(.small)
                        } else {
                            Text("Restore")
                                .font(Typography.sans(13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Palette.cream.opacity(0.82))
                    .frame(width: 94)
                    .padding(.vertical, compact ? 9 : 11)
                    .background(.black.opacity(0.2), in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(busy != nil)
                .accessibilityLabel("Restore purchases")
            }

            Text("One-time purchase · no renewal · no account")
                .font(Typography.sans(10, weight: .medium))
                .foregroundStyle(Palette.cream.opacity(0.46))

            Spacer(minLength: compact ? 2 : 6)
        }
        .padding(.horizontal, 22)
    }
}

private struct PremiumChoiceCard: View {
    let tier: Entitlement
    let product: Product?
    let featured: Bool
    let busy: Bool
    let onBuy: (Entitlement) async -> Void

    private var title: String {
        switch tier {
        case .free: "Free"
        case .plus: "Plus"
        case .unlimited: "Unlimited"
        }
    }

    private var shotLine: String {
        switch tier {
        case .free: "12 shots a day"
        case .plus: "72 shots a day"
        case .unlimited: "No daily limit"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(Typography.sans(12, weight: .bold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(featured ? Palette.gold : Palette.cream.opacity(0.62))
                    if featured {
                        Text("Best start")
                            .font(Typography.sans(9, weight: .bold))
                            .tracking(0.7)
                            .textCase(.uppercase)
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Palette.gold, in: Capsule())
                    }
                }

                Text(shotLine)
                    .font(Typography.display(featured ? 23 : 20))
                    .foregroundStyle(Palette.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("\(product?.displayPrice ?? tier.priceLabel) · pay once")
                    .font(Typography.sans(12, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.62))
            }

            Spacer(minLength: 8)

            Button { Task { await onBuy(tier) } } label: {
                ZStack {
                    if busy {
                        ProgressView()
                            .tint(Palette.ink)
                            .controlSize(.small)
                    } else {
                        Text("Own")
                            .font(Typography.sans(13, weight: .bold))
                    }
                }
                .foregroundStyle(Palette.ink)
                .frame(width: 62)
                .padding(.vertical, 10)
                .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(product == nil || busy)
            .opacity(product == nil ? 0.5 : 1)
            .accessibilityLabel("Buy \(title)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, featured ? 13 : 11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(featured ? Palette.gold.opacity(0.15) : Palette.cream.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(featured ? Palette.gold.opacity(0.5) : Palette.cream.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: featured ? Palette.gold.opacity(0.16) : .black.opacity(0.12), radius: 14, y: 8)
    }
}

private struct PageDots: View {
    let count: Int
    let selection: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == selection ? Palette.gold : Palette.cream.opacity(0.24))
                    .frame(width: index == selection ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.34, dampingFraction: 0.84), value: selection)
            }
        }
        .accessibilityLabel("Onboarding page \(selection + 1) of \(count)")
    }
}

private struct FeatureChips: View {
    let chips: [String]
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(Typography.sans(compact ? 10 : 11, weight: .bold))
                    .foregroundStyle(Palette.cream.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, compact ? 8 : 10)
                    .padding(.vertical, compact ? 6 : 7)
                    .background(.black.opacity(0.22), in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.12), lineWidth: 1))
            }
        }
    }
}

private struct MiniPromise: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.gold)
            Text(text)
                .font(Typography.sans(10, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.black.opacity(0.18), in: Capsule())
    }
}

/// The looping demo: a black island pill that smoothly stretches into a camera
/// window and shows the new camera controls.
private struct PullDownDemo: View {
    let compact: Bool

    private var openW: CGFloat { compact ? 184 : 214 }
    private var openH: CGFloat { compact ? 190 : 232 }

    var body: some View {
        PhaseAnimator([0.0, 1.0]) { progress in
            frameContent(progress)
        } animation: { _ in
            .easeInOut(duration: 1.45)
        }
        .frame(width: 250, height: compact ? 210 : 275)
    }

    @ViewBuilder private func frameContent(_ p: CGFloat) -> some View {
        let w = lerp(116, openW, p)
        let h = lerp(32, openH, p)
        let r = lerp(16, compact ? 32 : 40, p)

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(.black)
                .frame(width: w, height: h)
                .overlay(
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(Palette.amber.opacity(0.25 + 0.35 * p), lineWidth: 1.2)
                )
                .overlay(
                    cameraPreview(p)
                        .frame(width: w, height: h)
                        .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
                )
                .shadow(color: .black.opacity(0.36 * p), radius: 20 * p, y: 10 * p)
                .shadow(color: Palette.amber.opacity(0.16 * p), radius: 26 * p, y: 8 * p)
                .position(x: 125, y: h / 2)

            touchRing
                .position(x: 125, y: h + (compact ? 18 : 24))
        }
    }

    private func cameraPreview(_ p: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A3A49), Color(hex: 0x172330)],
                           startPoint: .top, endPoint: .bottom)
            FilmScene.blueHourRooftop.image(size: 420).swiftUIImage
                .resizable()
                .scaledToFill()
                .opacity(0.74)
            GrainOverlay(opacity: 0.22)

            VStack {
                HStack {
                    cameraTool("bolt.fill")
                    Spacer()
                    cameraTool("arrow.triangle.2.circlepath.camera")
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                Spacer()
                Circle()
                    .strokeBorder(Palette.cream.opacity(0.92), lineWidth: 4)
                    .background(Circle().fill(Palette.cream.opacity(0.16)))
                    .frame(width: compact ? 46 : 54, height: compact ? 46 : 54)
                    .padding(.bottom, 16)
            }
            .opacity(smoothstep(p, 0.35, 0.78))

            Image(systemName: "camera.aperture")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.85))
                .opacity(1 - smoothstep(p, 0.2, 0.65))
        }
    }

    private func cameraTool(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.cream)
            .frame(width: 34, height: 34)
            .background(.black.opacity(0.34), in: Circle())
    }

    private var touchRing: some View {
        ZStack {
            Circle().strokeBorder(Palette.cream.opacity(0.35), lineWidth: 7).frame(width: 44, height: 44)
            Circle().fill(Palette.cream.opacity(0.9)).frame(width: 25, height: 25)
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink.opacity(0.7))
        }
    }
}

private struct PrintFlowDemo: View {
    let compact: Bool
    @State private var image = FilmScene.sunlitPark.image(size: 420)

    var body: some View {
        PhaseAnimator([0.0, 1.0]) { progress in
            ZStack {
                drawerTray
                    .offset(y: compact ? 44 : 60)

                PrintView(
                    image: image,
                    isDeveloped: progress > 0.08,
                    developProgress: progress,
                    age: 0,
                    width: compact ? 132 : 158
                )
                .rotationEffect(.degrees(lerp(-9, 3, progress)))
                .offset(x: lerp(-54, 24, progress), y: lerp(-46, 34, progress))
                .shadow(color: Palette.gold.opacity(0.18 * progress), radius: 20, y: 9)

                Image(systemName: "sparkles")
                    .font(.system(size: compact ? 24 : 30, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                    .offset(x: 72, y: compact ? -48 : -62)
                    .opacity(smoothstep(progress, 0.45, 1))
            }
        } animation: { _ in
            .easeInOut(duration: 1.6)
        }
    }

    private var drawerTray: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Palette.charcoalDeep.opacity(0.66))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Palette.cream.opacity(0.1), lineWidth: 1)
            )
            .frame(width: compact ? 230 : 270, height: compact ? 92 : 112)
            .overlay(alignment: .topLeading) {
                Text("Drawer")
                    .font(Typography.display(compact ? 18 : 21))
                    .foregroundStyle(Palette.cream.opacity(0.72))
                    .padding(.leading, 18)
                    .padding(.top, 12)
            }
    }
}

private struct DrawerControlDemo: View {
    let compact: Bool

    var body: some View {
        PhaseAnimator([0.0, 1.0]) { progress in
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Palette.charcoalDeep.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Palette.cream.opacity(0.09), lineWidth: 1)
                    )
                    .frame(width: compact ? 250 : 292, height: compact ? 188 : 230)

                demoPrint(scene: .goldenHour, width: compact ? 82 : 98)
                    .rotationEffect(.degrees(lerp(-10, -18, progress)))
                    .offset(x: lerp(-28, -72, progress), y: lerp(-10, -34, progress))
                    .zIndex(1)
                demoPrint(scene: .pinkDusk, width: compact ? 82 : 98)
                    .rotationEffect(.degrees(lerp(6, 14, progress)))
                    .offset(x: lerp(20, 72, progress), y: lerp(4, -16, progress))
                    .zIndex(2)
                demoPrint(scene: .beachMorning, width: compact ? 84 : 102)
                    .rotationEffect(.degrees(lerp(1, -2, progress)))
                    .offset(x: lerp(0, 5, progress), y: lerp(18, 48, progress))
                    .zIndex(3)

                HStack(spacing: 86) {
                    Image(systemName: "arrow.left.and.right")
                    Image(systemName: "arrow.up.and.down")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.gold.opacity(0.75))
                .offset(y: compact ? 90 : 112)
                .opacity(smoothstep(progress, 0.28, 0.8))

                ButtonChrome(icon: "arrow.counterclockwise")
                    .offset(x: compact ? 96 : 112, y: compact ? -78 : -94)
            }
        } animation: { _ in
            .easeInOut(duration: 1.5)
        }
    }

    private func demoPrint(scene: FilmScene, width: CGFloat) -> some View {
        PrintView(image: scene.image(size: 360), isDeveloped: true, developProgress: 1, age: 0.2, width: width)
    }
}

private struct KeepDemo: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            folderCard(title: "Yesterday", count: "9 ready", icon: "folder")
            ZStack {
                PrintView(image: FilmScene.warmPortrait.image(size: 320), isDeveloped: true, age: 0.12, width: compact ? 72 : 88)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -18, y: 4)
                PrintView(image: FilmScene.beachMorning.image(size: 320), isDeveloped: true, age: 0.18, width: compact ? 72 : 88)
                    .rotationEffect(.degrees(8))
                    .offset(x: 18, y: -2)
            }
            folderCard(title: "Saved", count: "Photos", icon: "square.and.arrow.down")
        }
    }

    private func folderCard(title: String, count: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: compact ? 21 : 25, weight: .semibold))
                .foregroundStyle(Palette.gold)
            VStack(spacing: 2) {
                Text(title)
                    .font(Typography.sans(12, weight: .bold))
                    .foregroundStyle(Palette.cream)
                Text(count)
                    .font(Typography.sans(10, weight: .medium))
                    .foregroundStyle(Palette.cream.opacity(0.55))
            }
        }
        .frame(width: compact ? 82 : 96, height: compact ? 86 : 104)
        .background(Palette.charcoalDeep.opacity(0.66), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.cream.opacity(0.09), lineWidth: 1)
        )
    }
}

private struct ButtonChrome: View {
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.cream)
            .frame(width: 34, height: 34)
            .background(.black.opacity(0.28), in: Circle())
    }
}

private extension UIImage {
    var swiftUIImage: Image { Image(uiImage: self) }
}

// MARK: - Local interpolation helpers

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

private func smoothstep(_ x: CGFloat, _ edge0: CGFloat, _ edge1: CGFloat) -> CGFloat {
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}
