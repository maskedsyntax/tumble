import AVFoundation
import StoreKit
import SwiftData
import SwiftUI
import TumbleKit

/// First-run onboarding built around *doing*, not watching. The shooter takes a
/// real (gifted) first shot, shakes it to develop, and watches it land in the
/// Drawer — then meets a soft, anti-subscription premium moment. Reaching the
/// "aha" by acting is the strongest retention lever.
struct OnboardingScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    let onDone: () -> Void

    enum Step: Int, CaseIterable { case welcome, capture, develop, payoff, premium }

    @State private var step: Step = .welcome
    @State private var appeared = false
    @State private var busy: String?
    @State private var capturedImage: UIImage?
    @State private var firstPhoto: Photo?

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 720
            ZStack {
                GraincoreBackground()

                VStack(spacing: 0) {
                    if step != .premium {
                        StepDots(count: 4, index: step.rawValue)
                            .padding(.top, geo.safeAreaInsets.top + 12)
                    }
                    content(compact: compact)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, step == .premium ? geo.safeAreaInsets.top + 14 : 4)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 16))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }
            .ignoresSafeArea()
        }
        .task {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            await app.startStore()
            applyDebugStep()
        }
    }

    @ViewBuilder private func content(compact: Bool) -> some View {
        switch step {
        case .welcome:
            WelcomeStep(compact: compact) { advance(.capture) }
        case .capture:
            CaptureStep(compact: compact) { image in
                capturedImage = image
                advance(.develop)
            }
        case .develop:
            DevelopStep(compact: compact, image: capturedImage) {
                storeFirstPrint()
                advance(.payoff)
            }
        case .payoff:
            PayoffStep(compact: compact, image: capturedImage) { advance(.premium) }
        case .premium:
            PremiumOnboardingPage(
                compact: compact,
                image: capturedImage,
                plusProduct: app.purchases.product(for: .plus),
                unlimitedProduct: app.purchases.product(for: .unlimited),
                busy: busy,
                onBuy: buy,
                onRestore: restore,
                onStartFree: onDone
            )
        }
    }

    private func advance(_ s: Step) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) { step = s }
    }

    /// Persist the developed first print — gifted, so it does not spend a shot.
    @MainActor private func storeFirstPrint() {
        guard let capturedImage else { return }
        let photo = CaptureService.store(
            rawImage: capturedImage, source: .app, roll: app.roll, in: context, consumesRoll: false
        )
        photo?.isDeveloped = true
        photo?.developProgress = 1
        try? context.save()
        firstPhoto = photo
        app.capturedCount += 1
    }

    @MainActor private func buy(_ tier: Entitlement) async {
        guard let product = app.purchases.product(for: tier), busy == nil else { return }
        busy = tier.productID
        defer { busy = nil }
        if await app.purchases.purchase(product) {
            app.syncEntitlement()
            onDone()
        }
    }

    @MainActor private func restore() async {
        guard busy == nil else { return }
        busy = "restore"
        defer { busy = nil }
        await app.purchases.restore()
        app.syncEntitlement()
        if app.purchases.entitlement > .free { onDone() }
    }

    private func applyDebugStep() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-onbCapture") { step = .capture }
        else if args.contains("-onbDevelop") { capturedImage = FilmScene.goldenHour.image(); step = .develop }
        else if args.contains("-onbPayoff") { capturedImage = FilmScene.goldenHour.image(); step = .payoff }
        else if args.contains("-onbPremium") { step = .premium }
    }
}

// MARK: - Welcome / identity

private struct WelcomeStep: View {
    let compact: Bool
    let onNext: () -> Void
    @State private var apertureIn = false

    var body: some View {
        VStack(spacing: compact ? 16 : 22) {
            Spacer(minLength: 0)

            heroFan
                .frame(height: compact ? 210 : 260)

            HStack(spacing: 9) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 32, height: 32)
                    .background(Palette.gold, in: Circle())
                    .rotationEffect(.degrees(apertureIn ? 0 : -120))
                    .scaleEffect(apertureIn ? 1 : 0.5)
                Text("Tumble").font(Typography.display(24)).foregroundStyle(Palette.cream)
            }

            VStack(spacing: compact ? 8 : 11) {
                Text("A camera that\nmakes you wait.")
                    .font(Typography.display(compact ? 30 : 36))
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.center)
                Text("Twelve shots a day. Shake each one to develop. No feed, no filters, no rush.")
                    .font(Typography.sans(compact ? 14 : 15))
                    .foregroundStyle(Palette.cream.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Label("No account · No cloud · Photos never leave your phone", systemImage: "lock.shield")
                .font(Typography.sans(11, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.6))
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 0)

            PrimaryCTA(title: "Take your first shot", icon: "arrow.right", action: onNext)
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.15)) { apertureIn = true }
        }
    }

    private var heroFan: some View {
        ZStack {
            PrintView(image: FilmScene.blueHourRooftop.image(size: 420), isDeveloped: true, age: 0.28,
                      width: compact ? 128 : 150)
                .rotationEffect(.degrees(-12)).offset(x: -58, y: 12)
            PrintView(image: FilmScene.sunlitPark.image(size: 420), isDeveloped: true, age: 0.1,
                      width: compact ? 132 : 156)
                .rotationEffect(.degrees(10)).offset(x: 58, y: 6)
            PrintView(image: FilmScene.goldenHour.image(size: 480), isDeveloped: true, age: 0.05,
                      caption: "first light", width: compact ? 150 : 178)
                .rotationEffect(.degrees(-2)).offset(y: -8)
                .parallax(6)
        }
        .shadow(color: Palette.gold.opacity(0.16), radius: 26, y: 14)
    }
}

// MARK: - Capture (do it)

private struct CaptureStep: View {
    let compact: Bool
    let onCaptured: (UIImage) -> Void
    @StateObject private var camera = CameraController()
    @State private var flash = false
    @State private var busy = false

    var body: some View {
        VStack(spacing: compact ? 14 : 20) {
            stepText(
                kicker: "Your turn",
                title: "Take your first shot.",
                message: "Point, and press. Don't overthink it — that's the whole idea.",
                compact: compact
            )

            Spacer(minLength: 0)

            ZStack {
                Group {
                    if camera.isSimulated {
                        ZStack {
                            LinearGradient(colors: [Color(hex: 0x2A3A49), Color(hex: 0x172330)],
                                           startPoint: .top, endPoint: .bottom)
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(Palette.cream.opacity(0.7))
                        }
                    } else {
                        CameraPreview(session: camera.session)
                    }
                }
                GrainOverlay(opacity: 0.16)
                Color.white.opacity(flash ? 0.9 : 0)
            }
            .frame(width: compact ? 250 : 288, height: compact ? 300 : 344)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(Palette.amber.opacity(0.3), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.4), radius: 22, y: 12)

            Spacer(minLength: 0)

            Button(action: capture) {
                ZStack {
                    Circle().strokeBorder(Palette.cream.opacity(0.9), lineWidth: 5).frame(width: 78, height: 78)
                    Circle().fill(Palette.cream).frame(width: 62, height: 62).scaleEffect(busy ? 0.86 : 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(busy)
            .accessibilityLabel("Take a shot")
        }
        .padding(.horizontal, 28)
        .task {
            _ = await AVCaptureDevice.requestAccess(for: .video)
            camera.start()
        }
        .onDisappear { camera.stop() }
    }

    private func capture() {
        guard !busy else { return }
        busy = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        camera.capture { image in
            withAnimation(.easeOut(duration: 0.07)) { flash = true }
            withAnimation(.easeIn(duration: 0.22).delay(0.07)) { flash = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { onCaptured(image) }
        }
    }
}

// MARK: - Develop (the hero moment)

private struct DevelopStep: View {
    let compact: Bool
    let image: UIImage?
    let onDeveloped: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shake = ShakeMonitor()
    @State private var progress: Double = 0
    @State private var holding = false
    @State private var lastHaptic = Date.distantPast

    private var usesShake: Bool { shake.isAvailable && !reduceMotion }
    private var developed: Bool { progress >= 1 }

    var body: some View {
        VStack(spacing: compact ? 14 : 20) {
            stepText(
                kicker: "The best part",
                title: developed ? "There it is." : "Now shake it to life.",
                message: developed
                    ? "That wait? That's the whole point."
                    : "Give your phone a shake and watch it come up, like real instant film.",
                compact: compact
            )

            Spacer(minLength: 0)

            PrintView(image: image, isDeveloped: developed, developProgress: progress, width: compact ? 220 : 262)
                .overlay(bloom)
                .scaleEffect(developed ? 1 : 0.99)
                .rotationEffect(.degrees(progress < 1 && holding ? 1 : 0))
                .animation(.easeOut(duration: 0.4), value: developed)

            Spacer(minLength: 0)

            if developed {
                PrimaryCTA(title: "See it in the Drawer", icon: "arrow.right", action: onDeveloped)
            } else if usesShake {
                Text("Shake to develop")
                    .font(Typography.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.8))
                    .padding(.bottom, 6)
            } else {
                holdButton
            }
        }
        .padding(.horizontal, 28)
        .task {
            guard usesShake else { return }
            shake.onShake = { energy in advance(by: energy * 0.05) }
            shake.start()
        }
        .onDisappear { shake.stop() }
    }

    private var bloom: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(RadialGradient(colors: [.white.opacity(0.8), .clear], center: .center, startRadius: 0, endRadius: 160))
            .opacity(smoothstep(progress, 0.72, 0.95) * (1 - smoothstep(progress, 0.95, 1.02)))
            .allowsHitTesting(false)
    }

    private var holdButton: some View {
        Text(holding ? "Developing…" : "Hold to develop")
            .font(Typography.sans(15, weight: .bold))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.amber, in: Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !holding { startHold() } }
                    .onEnded { _ in holding = false }
            )
    }

    private func startHold() {
        holding = true
        Task {
            while holding && progress < 1 {
                advance(by: 0.014)
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func advance(by amount: Double) {
        guard progress < 1 else { return }
        progress = min(1, progress + amount)
        rattle()
        if progress >= 1 { finish() }
    }

    private func rattle() {
        let now = Date()
        guard now.timeIntervalSince(lastHaptic) > 0.09 else { return }
        lastHaptic = now
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    private func finish() {
        holding = false
        shake.stop()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Payoff / endowment

private struct PayoffStep: View {
    let compact: Bool
    let image: UIImage?
    let onNext: () -> Void
    @State private var dropped = false
    @State private var askedNotif = false

    var body: some View {
        VStack(spacing: compact ? 12 : 18) {
            stepText(
                kicker: "Yours",
                title: "Here's your first one.",
                message: "Twelve fresh every morning. Twelve is on purpose — enough to make each one count.",
                compact: compact
            )

            Spacer(minLength: 0)

            payoffHero
            .frame(height: compact ? 224 : 268)

            Spacer(minLength: 0)

            // Value-first: offer the morning nudge now that they've felt the loop.
            notifAsk

            PrimaryCTA(title: "Into the Drawer", icon: "tray.full", action: onNext)
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.15)) { dropped = true }
        }
    }

    @ViewBuilder private var notifAsk: some View {
        if !askedNotif && !RollNotificationScheduler.hasAsked {
            HStack(spacing: 10) {
                Image(systemName: "sun.horizon")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.amber)
                VStack(alignment: .leading, spacing: 1) {
                    Text("A nudge each morning?")
                        .font(Typography.sans(13, weight: .semibold)).foregroundStyle(Palette.cream)
                    Text("We'll ping you when your fresh roll lands.")
                        .font(Typography.sans(11)).foregroundStyle(Palette.cream.opacity(0.6))
                }
                Spacer(minLength: 6)
                Button {
                    askedNotif = true
                    Task { await RollNotificationScheduler.requestAndSchedule() }
                } label: {
                    Text("Yes")
                        .font(Typography.sans(13, weight: .bold)).foregroundStyle(Palette.ink)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Palette.gold, in: Capsule())
                }
                .buttonStyle(.plain)
                Button { askedNotif = true } label: {
                    Text("Not now")
                        .font(Typography.sans(12, weight: .semibold)).foregroundStyle(Palette.cream.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.black.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.cream.opacity(0.12)))
            .transition(.opacity)
        }
    }

    private var payoffHero: some View {
        HStack(alignment: .center, spacing: compact ? 10 : 16) {
            VStack(alignment: .leading, spacing: compact ? 7 : 9) {
                HStack(spacing: 7) {
                    Image(systemName: "tray.full")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Saved to Drawer")
                        .font(Typography.sans(11, weight: .bold))
                        .tracking(1.1)
                        .textCase(.uppercase)
                }
                .foregroundStyle(Palette.gold)

                Text("It's in.")
                    .font(Typography.display(compact ? 20 : 24))
                    .foregroundStyle(Palette.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, compact ? 10 : 14)

            PrintView(image: image, isDeveloped: true, width: compact ? 146 : 172)
                .rotationEffect(.degrees(dropped ? -4 : 2))
                .offset(y: dropped ? 0 : (compact ? -96 : -120))
                .scaleEffect(dropped ? 0.92 : 1)
        }
        .padding(.horizontal, compact ? 8 : 12)
    }
}

// MARK: - Shared bits

/// A shared title block for the do-it steps.
private func stepText(kicker: String, title: String, message: String, compact: Bool) -> some View {
    VStack(spacing: compact ? 6 : 9) {
        Text(kicker).kicker()
        Text(title)
            .font(Typography.display(compact ? 27 : 32))
            .foregroundStyle(Palette.cream)
            .multilineTextAlignment(.center)
            .lineLimit(2).minimumScaleFactor(0.85)
        Text(message)
            .font(Typography.sans(compact ? 13 : 15))
            .foregroundStyle(Palette.cream.opacity(0.72))
            .multilineTextAlignment(.center)
            .lineLimit(3).minimumScaleFactor(0.9)
    }
    .padding(.horizontal, 8)
    .padding(.top, compact ? 8 : 20)
}

private struct PrimaryCTA: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                Image(systemName: icon)
            }
            .font(Typography.sans(16, weight: .bold))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Palette.gold, in: Capsule())
            .shadow(color: Palette.gold.opacity(0.28), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct StepDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Palette.gold : Palette.cream.opacity(0.24))
                    .frame(width: i == index ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.34, dampingFraction: 0.84), value: index)
            }
        }
    }
}

// MARK: - Premium (soft, anti-subscription)

private struct PremiumOnboardingPage: View {
    let compact: Bool
    let image: UIImage?
    let plusProduct: Product?
    let unlimitedProduct: Product?
    let busy: String?
    let onBuy: (Entitlement) async -> Void
    let onRestore: () async -> Void
    let onStartFree: () -> Void

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            Spacer(minLength: compact ? 0 : 6)

            VStack(spacing: compact ? 5 : 7) {
                Text("Pay once. Never again.").kicker()
                Text("Start with the full camera.")
                    .font(Typography.display(compact ? 25 : 31))
                    .foregroundStyle(Palette.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.82)
            }

            PremiumFinaleHero(compact: compact, image: image)

            HStack(spacing: 8) {
                MiniPromise(icon: "folder", text: "Collections")
                MiniPromise(icon: "square.and.arrow.down", text: "Save")
                MiniPromise(icon: "infinity", text: "More shots")
            }

            VStack(spacing: compact ? 8 : 10) {
                PremiumChoiceCard(tier: .plus, product: plusProduct, featured: true,
                                  busy: busy == Entitlement.plus.productID, onBuy: onBuy)
                PremiumChoiceCard(tier: .unlimited, product: unlimitedProduct, featured: false,
                                  busy: busy == Entitlement.unlimited.productID, onBuy: onBuy)
            }

            HStack(spacing: 12) {
                Button(action: onStartFree) {
                    Text("Start with 12 free shots")
                        .font(Typography.sans(13, weight: .semibold))
                        .foregroundStyle(Palette.cream.opacity(0.82))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 10 : 12)
                        .background(.black.opacity(0.2), in: Capsule())
                        .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button { Task { await onRestore() } } label: {
                    ZStack {
                        if busy == "restore" {
                            ProgressView().tint(Palette.cream).controlSize(.small)
                        } else {
                            Text("Restore").font(Typography.sans(13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Palette.cream.opacity(0.82))
                    .frame(width: 94)
                    .padding(.vertical, compact ? 10 : 12)
                    .background(.black.opacity(0.2), in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(busy != nil)
            }

            Text("One-time purchase · no renewal · no account")
                .font(Typography.sans(10, weight: .medium))
                .foregroundStyle(Palette.cream.opacity(0.46))

            Spacer(minLength: compact ? 2 : 6)
        }
        .padding(.horizontal, 24)
    }
}

private struct PremiumFinaleHero: View {
    let compact: Bool
    let image: UIImage?

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: compact ? 10 : 14) {
                promiseNote
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                printStack
            }
            .padding(.horizontal, compact ? 8 : 12)
        }
        .frame(height: compact ? 118 : 146)
        .padding(.top, compact ? 0 : 4)
        .padding(.bottom, compact ? 2 : 6)
    }

    private var promiseNote: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 9) {
            HStack(spacing: 7) {
                Image(systemName: "tray.full")
                    .font(.system(size: 11, weight: .semibold))
                Text("First print saved")
                    .font(Typography.sans(10, weight: .bold))
                    .tracking(0.9)
                    .textCase(.uppercase)
            }
            .foregroundStyle(Palette.gold)

            Text("Keep the Drawer.")
                .font(Typography.display(compact ? 20 : 24))
                .foregroundStyle(Palette.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(alignment: .leading, spacing: compact ? 4 : 5) {
                PremiumStamp(icon: "checkmark.seal", text: "No subscription")
                PremiumStamp(icon: "lock.shield", text: "No account")
            }
        }
        .padding(.leading, compact ? 4 : 6)
    }

    private var printStack: some View {
        PrintView(
            image: image ?? FilmScene.goldenHour.image(size: 420),
            isDeveloped: true,
            developProgress: 1,
            age: 0.04,
            caption: compact ? nil : "first roll",
            width: compact ? 98 : 122
        )
        .rotationEffect(.degrees(-4))
        .shadow(color: Palette.gold.opacity(0.2), radius: 18, y: 8)
    }
}

private struct PremiumStamp: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Palette.gold)
                .frame(width: 13)
            Text(text)
                .font(Typography.sans(10, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
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
                        .font(Typography.sans(12, weight: .bold)).tracking(1.2).textCase(.uppercase)
                        .foregroundStyle(featured ? Palette.gold : Palette.cream.opacity(0.62))
                    if featured {
                        Text("Best start")
                            .font(Typography.sans(9, weight: .bold)).tracking(0.7).textCase(.uppercase)
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Palette.gold, in: Capsule())
                    }
                }
                Text(shotLine)
                    .font(Typography.display(featured ? 23 : 20)).foregroundStyle(Palette.cream)
                    .lineLimit(1).minimumScaleFactor(0.82)
                Text("\(product?.displayPrice ?? tier.priceLabel) · pay once")
                    .font(Typography.sans(12, weight: .semibold)).foregroundStyle(Palette.cream.opacity(0.62))
            }
            Spacer(minLength: 8)
            Button { Task { await onBuy(tier) } } label: {
                ZStack {
                    if busy { ProgressView().tint(Palette.ink).controlSize(.small) }
                    else { Text("Own").font(Typography.sans(13, weight: .bold)) }
                }
                .foregroundStyle(Palette.ink)
                .frame(width: 62).padding(.vertical, 10)
                .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(product == nil || busy)
            .opacity(product == nil ? 0.5 : 1)
            .accessibilityLabel("Buy \(title)")
        }
        .padding(.horizontal, 14).padding(.vertical, featured ? 13 : 11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    featured
                        ? LinearGradient(
                            colors: [Palette.gold.opacity(0.2), Color(hex: 0x2D3741).opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Palette.charcoalDeep.opacity(0.92), Palette.blueDeep.opacity(0.74)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(featured ? Palette.gold.opacity(0.5) : Palette.cream.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: featured ? Palette.gold.opacity(0.16) : .black.opacity(0.12), radius: 14, y: 8)
    }
}

private struct MiniPromise: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.gold)
            Text(text)
                .font(Typography.sans(10, weight: .semibold)).foregroundStyle(Palette.cream.opacity(0.72))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 7)
        .background(.black.opacity(0.18), in: Capsule())
    }
}

// MARK: - Local helpers

private func smoothstep(_ x: CGFloat, _ edge0: CGFloat, _ edge1: CGFloat) -> CGFloat {
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}
