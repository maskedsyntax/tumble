import SwiftUI
import SwiftData
import TumbleKit

/// The app's home. The whole screen is the **Drawer** — your pile of prints —
/// not a camera. The camera lives in the Dynamic Island / top handle: pull it
/// down to shoot, and the shot lands here.
struct HomeScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var app
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var selected: Photo?
    @State private var showPaywall = false
    @State private var nudgeDismissed = false
    @State private var showHint = false
    @AppStorage("tumble.hasSeenIslandHint") private var seenHint = false

    /// Prompt to own more when the daily roll is running low.
    private let lowRollThreshold = 3

    private var developedCount: Int { photos.filter(\.isDeveloped).count }
    private var remaining: Int? { app.roll.remaining }
    private var showsNudge: Bool {
        guard !app.roll.isUnlimited, let r = remaining else { return false }
        if r == 0 { return true }                       // empty roll: always informs
        return r <= lowRollThreshold && !nudgeDismissed  // low: dismissible
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                GraincoreBackground()

                // Home surface: the Drawer.
                VStack(spacing: 8) {
                    header
                        .padding(.top, geo.safeAreaInsets.top + 46)
                        .padding(.horizontal, 20)
                    DrawerPile(photos: photos) { selected = $0 }
                }

                // The camera handle (island on DI phones, floating handle elsewhere).
                IslandCamera(
                    screenWidth: geo.size.width,
                    topInset: geo.safeAreaInsets.top,
                    hasIsland: geo.safeAreaInsets.top >= 51,
                    onNeedMore: { showPaywall = true },
                    autoOpen: ProcessInfo.processInfo.arguments.contains("-island")
                )
                .environment(app)

                // Gentle "own more" nudge as the roll runs low.
                if showsNudge {
                    lowRollNudge
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.horizontal, 18)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // One-time coachmark: teach the pull-down camera.
                if showHint {
                    coachmark(topInset: geo.safeAreaInsets.top)
                }
            }
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showsNudge)
        .fullScreenCover(item: $selected) { photo in
            PrintStage(photo: photo, developed: photos.filter(\.isDeveloped))
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environment(app) }
        .task { await app.startStore() }
        .onChange(of: photos.count) { _, n in app.capturedCount = n }
        .onAppear {
            DebugSeed.run(in: context)
            app.capturedCount = photos.count
            if !seenHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) { showHint = true }
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-develop") {
                selected = photos.first { !$0.isDeveloped }
            } else if ProcessInfo.processInfo.arguments.contains("-detail") {
                selected = photos.first { $0.isDeveloped }
            }
            if ProcessInfo.processInfo.arguments.contains("-paywall") { showPaywall = true }
            if ProcessInfo.processInfo.arguments.contains("-lowroll") {
                for _ in 0..<10 { app.roll.consumeShot() }
            }
            if ProcessInfo.processInfo.arguments.contains("-emptyroll") {
                for _ in 0..<12 { app.roll.consumeShot() }
            }
            if ProcessInfo.processInfo.arguments.contains("-hint") { showHint = true }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Drawer")
                    .font(Typography.display(26))
                    .foregroundStyle(Palette.cream)
                if !photos.isEmpty {
                    Text("\(developedCount) developed · \(photos.count) in the drawer")
                        .font(Typography.sans(12))
                        .foregroundStyle(Palette.cream.opacity(0.55))
                }
            }
            Spacer()
            Button { showPaywall = true } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Palette.cream)
                    .padding(9).background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Plans and about")
        }
    }

    // MARK: Low-roll nudge

    private var lowRollNudge: some View {
        let isEmpty = (remaining ?? 0) == 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isEmpty ? "That's your twelve for today." : "\(remaining ?? 0) shots left today.")
                    .font(Typography.sans(14, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                Text(isEmpty ? "Fresh roll at sunrise — or own more now." : "Running low? Own more, once.")
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.65))
            }
            Spacer(minLength: 8)
            Button { showPaywall = true } label: {
                Text("Own more")
                    .font(Typography.sans(13, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            if !isEmpty {
                Button { withAnimation { nudgeDismissed = true } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.cream.opacity(0.6))
                        .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.charcoalDeep.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.amber.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }

    // MARK: Coachmark

    private func coachmark(topInset: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { dismissHint() }

            VStack(spacing: 12) {
                Image(systemName: "chevron.compact.up")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Palette.amber)
                VStack(spacing: 6) {
                    Text("Your camera lives up here")
                        .font(Typography.display(20)).foregroundStyle(Palette.cream)
                    Text("Pull it down to take a shot. Twelve a day —\nshake each one to develop it.")
                        .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                Button { dismissHint() } label: {
                    Text("Got it")
                        .font(Typography.sans(14, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .background(Palette.amber, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.top, topInset + 54)
        }
        .transition(.opacity)
    }

    private func dismissHint() {
        withAnimation(.easeOut(duration: 0.3)) { showHint = false }
        seenHint = true
    }
}
