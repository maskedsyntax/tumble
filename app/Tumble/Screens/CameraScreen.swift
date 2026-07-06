import SwiftUI
import SwiftData
import TumbleKit

/// The camera — a deliberately quiet, single-shutter viewfinder. No burst, no
/// zoom clutter. A soft grain sits over the live feed so even the preview feels
/// filmic. The roll counter is present but never nags.
struct CameraScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var app
    @StateObject private var camera = CameraController()

    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var showDrawer = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var flash = false
    @State private var tossing = false

    var body: some View {
        ZStack {
            viewfinder
            GrainOverlay(opacity: 0.14)

            // Shutter flash.
            Color.white.opacity(flash ? 0.85 : 0).ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .onAppear {
            camera.start()
            DebugSeed.run(in: context)
            if ProcessInfo.processInfo.arguments.contains("-drawer") { showDrawer = true }
            if ProcessInfo.processInfo.arguments.contains("-paywall") { showPaywall = true }
            if ProcessInfo.processInfo.arguments.contains("-settings") { showSettings = true }
        }
        .onDisappear { camera.stop() }
        .task { await app.startStore() }
        .fullScreenCover(isPresented: $showDrawer) {
            DrawerScreen().environment(app)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(app)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(app)
        }
    }

    // MARK: Viewfinder

    @ViewBuilder private var viewfinder: some View {
        if camera.isSimulated {
            // No camera (Simulator): a filmic stand-in so the UI still reads.
            GraincoreBackground()
        } else {
            CameraPreview(session: camera.session).ignoresSafeArea()
        }
    }

    // MARK: Bars

    private var topBar: some View {
        HStack {
            Text(app.roll.remainingLabel)
                .font(Typography.sans(13, weight: .semibold))
                .foregroundStyle(Palette.cream)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.black.opacity(0.28), in: Capsule())
                .accessibilityLabel("\(app.roll.remainingLabel) in your roll")
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .padding(9).background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    @ViewBuilder private var bottomBar: some View {
        if app.roll.canShoot {
            HStack(alignment: .center) {
                drawerButton
                Spacer()
                shutter
                Spacer()
                Color.clear.frame(width: 56, height: 56) // balance the shutter
            }
        } else {
            emptyRoll
        }
    }

    private var shutter: some View {
        Button(action: capture) {
            ZStack {
                Circle().strokeBorder(Palette.cream.opacity(0.9), lineWidth: 4)
                    .frame(width: 74, height: 74)
                Circle().fill(Palette.cream)
                    .frame(width: 60, height: 60)
                    .scaleEffect(tossing ? 0.86 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Take a shot")
    }

    private var drawerButton: some View {
        Button { showDrawer = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Palette.printStock)
                    .frame(width: 44, height: 54)
                    .rotationEffect(.degrees(-8))
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                if !photos.isEmpty {
                    Text("\(photos.count)")
                        .font(Typography.sans(12, weight: .bold))
                        .foregroundStyle(Palette.ink)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open the Drawer")
    }

    private var emptyRoll: some View {
        VStack(spacing: 6) {
            Text("That's the roll for today.")
                .font(Typography.display(20))
                .foregroundStyle(Palette.cream)
            Text("Fresh twelve at sunrise.")
                .font(Typography.sans(14))
                .foregroundStyle(Palette.cream.opacity(0.7))
            HStack(spacing: 10) {
                Button { showDrawer = true } label: {
                    Text("Open the Drawer")
                        .font(Typography.sans(14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(Palette.amber, in: Capsule())
                }
                .buttonStyle(.plain)

                if app.purchases.entitlement != .unlimited {
                    Button { showPaywall = true } label: {
                        Text("Own more")
                            .font(Typography.sans(14, weight: .semibold))
                            .foregroundStyle(Palette.cream)
                            .padding(.horizontal, 18).padding(.vertical, 9)
                            .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Capture

    private func capture() {
        guard app.roll.canShoot else { return }
        let haptic = UIImpactFeedbackGenerator(style: .heavy)
        haptic.impactOccurred()

        camera.capture { image in
            withAnimation(.easeOut(duration: 0.08)) { flash = true }
            withAnimation(.easeIn(duration: 0.25).delay(0.08)) { flash = false }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { tossing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { tossing = false }
            app.store(rawImage: image, in: context)
        }
    }
}
