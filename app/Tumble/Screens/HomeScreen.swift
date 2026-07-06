import SwiftUI
import SwiftData
import TumbleKit

/// The app's home. The whole screen is the **Drawer** — your pile of prints —
/// not a camera. The camera lives in the Dynamic Island: pull it down to shoot,
/// and the shot lands here. This is the Miko-style pivot away from a
/// full-screen viewfinder.
struct HomeScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var app
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var selected: Photo?
    @State private var showSettings = false
    @State private var showPaywall = false

    private var developedCount: Int { photos.filter(\.isDeveloped).count }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                GraincoreBackground()

                // Home surface: the Drawer.
                VStack(spacing: 8) {
                    header
                        // Sit clearly below the island "12 left today" chip.
                        .padding(.top, geo.safeAreaInsets.top + 46)
                        .padding(.horizontal, 20)
                    DrawerPile(photos: photos) { selected = $0 }
                }

                // The camera, tucked into the Dynamic Island.
                IslandCamera(
                    screenWidth: geo.size.width,
                    topInset: geo.safeAreaInsets.top,
                    autoOpen: ProcessInfo.processInfo.arguments.contains("-island")
                )
                .environment(app)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $selected) { photo in
            PrintStage(photo: photo, developed: photos.filter(\.isDeveloped))
        }
        .sheet(isPresented: $showSettings) { SettingsView().environment(app) }
        .sheet(isPresented: $showPaywall) { PaywallView().environment(app) }
        .task { await app.startStore() }
        .onChange(of: photos.count) { _, n in app.capturedCount = n }
        .onAppear {
            DebugSeed.run(in: context)
            app.capturedCount = photos.count
            if ProcessInfo.processInfo.arguments.contains("-develop") {
                selected = photos.first { !$0.isDeveloped }
            } else if ProcessInfo.processInfo.arguments.contains("-detail") {
                selected = photos.first { $0.isDeveloped }
            }
            if ProcessInfo.processInfo.arguments.contains("-paywall") { showPaywall = true }
            if ProcessInfo.processInfo.arguments.contains("-settings") { showSettings = true }
        }
    }

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
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .padding(9).background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }
}
