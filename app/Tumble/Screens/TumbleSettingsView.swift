import SwiftData
import SwiftUI
import TumbleAnalytics
import TumbleKit

struct TumbleSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var analyticsEnabled = false
    @State private var showAccount = false
    @State private var showComplete = false
    var onReplayIntroduction: (() -> Void)? = nil

    private var showsUpgrade: Bool {
        if DebugLaunch.previewsFreeSettings { return true }
        return app.purchases.accessState != .complete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GraincoreBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if showsUpgrade {
                            Button { showComplete = true } label: { upgradeCard }
                                .buttonStyle(.plain)
                        }

                        settingsSection("Account") {
                            Button { showAccount = true } label: {
                                settingRow(
                                    "Tumble account",
                                    detail: app.account.isSignedIn ? "Signed in · purchases stay connected" : "Optional · only needed for purchases",
                                    icon: "person.crop.circle"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        settingsSection("Privacy") {
                            settingCard {
                                Toggle(isOn: Binding(
                                    get: { analyticsEnabled },
                                    set: { value in
                                        analyticsEnabled = value
                                        TumbleAnalytics.shared.setEnabled(value)
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Share anonymous diagnostics")
                                            .font(Typography.sans(15, weight: .semibold))
                                        Text("Crash reports and masked usage events. Photo pixels are never included.")
                                            .font(Typography.sans(12))
                                            .foregroundStyle(Palette.cream.opacity(0.58))
                                    }
                                }
                                .tint(Palette.gold)
                            }

                            Link(destination: URL(string: "https://gettumbleapp.com/privacy")!) {
                                settingRow("Privacy policy", detail: "Read how Tumble handles your data", icon: "lock.shield")
                            }
                        }

                        settingsSection("Help") {
                            if let onReplayIntroduction {
                                Button {
                                    dismiss()
                                    onReplayIntroduction()
                                } label: {
                                    settingRow("Try the introduction again", detail: "Explore films and the postcard finish", icon: "sparkles.rectangle.stack")
                                }
                                .buttonStyle(.plain)
                            }
                            Link(destination: URL(string: "mailto:aftaab@aftaab.dev?subject=Tumble%203")!) {
                                settingRow("Contact support", detail: "Questions, feedback, or a problem", icon: "envelope")
                            }
                        }

                        Text("Tumble \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.1")")
                            .font(Typography.sans(12))
                            .foregroundStyle(Palette.cream.opacity(0.42))
                            .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(Palette.gold) }
            }
            .toolbarBackground(Palette.blueDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { analyticsEnabled = TumbleAnalytics.shared.isEnabled }
        .sheet(isPresented: $showComplete) { CompletePaywallView().environment(app) }
        .sheet(isPresented: $showAccount) { AccountView().environment(app) }
    }

    private var upgradeCard: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().fill(Palette.gold.opacity(0.18))
                Image(systemName: "camera.filters")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Palette.gold)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("TUMBLE COMPLETE")
                    .font(Typography.sans(9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Palette.gold)
                Text("Unlock every film")
                    .font(Typography.display(21))
                    .foregroundStyle(Palette.cream)
                Text("15 additional films · pay once")
                    .font(Typography.sans(11, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.58))
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 31, height: 31)
                .background(Palette.gold, in: Circle())
        }
        .padding(17)
        .background(
            LinearGradient(
                colors: [Palette.charcoalDeep.opacity(0.96), Palette.blueDeep.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Palette.gold.opacity(0.30))
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(Typography.sans(10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Palette.gold.opacity(0.78))
                .padding(.horizontal, 4)
            VStack(spacing: 10, content: content)
        }
    }

    private func settingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundStyle(Palette.cream)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.charcoalDeep.opacity(0.62), in: RoundedRectangle(cornerRadius: 18))
    }

    private func settingRow(_ title: String, detail: String, icon: String) -> some View {
        settingCard {
            HStack(spacing: 13) {
                Image(systemName: icon).foregroundStyle(Palette.gold).frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(Typography.sans(15, weight: .semibold))
                    Text(detail).font(Typography.sans(12)).foregroundStyle(Palette.cream.opacity(0.58))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.cream.opacity(0.4))
            }
        }
    }
}

struct DrawerLibraryView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]
    @State private var selected: Photo?

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drawer").font(Typography.display(28)).foregroundStyle(Palette.cream)
                        Text("Your saved prints")
                            .font(Typography.sans(12)).foregroundStyle(Palette.cream.opacity(0.58))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Palette.cream)
                            .padding(10).background(.black.opacity(0.28), in: Circle())
                    }
                }
                .padding(.horizontal, 20)

                if photos.isEmpty {
                    Spacer()
                    Text("The Drawer is empty.").font(Typography.display(23)).foregroundStyle(Palette.cream)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 18) {
                            ForEach(photos) { photo in
                                DrawerPrintTile(photo: photo) {
                                    selected = photo
                                    if !photo.isDeveloped { Task { await finish(photo) } }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .padding(.top, 10)
        }
        .fullScreenCover(item: $selected) { PrintStage(photo: $0, developed: photos.filter(\.isDeveloped)).environment(app) }
    }

    private func finish(_ photo: Photo) async {
        guard let raw = await PhotoStore.loadImageDataAsync(named: photo.rawImageName) else { return }
        let grade = photo.filmStock.grade
        let capturedAt = photo.capturedAt
        guard let rendered = await Task.detached(priority: .userInitiated, operation: {
            TumblePhotoFilter.renderMemoryPhotoData(from: raw, grade: grade, capturedAt: capturedAt)
        }).value else { return }
        photo.developedImageName = try? await PhotoStore.writeImageAsync(rendered, id: photo.id, kind: .developed)
        photo.developProgress = 1
        photo.isDeveloped = true
        try? context.save()
    }
}

private struct DrawerPrintTile: View {
    let photo: Photo
    let action: () -> Void
    @State private var image: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PrintView(image: image, isDeveloped: photo.isDeveloped, width: 132)
                Text(photo.isDeveloped ? photo.filmStock.name : "Finish developing")
                    .font(Typography.sans(11, weight: .semibold))
                    .foregroundStyle(photo.isDeveloped ? Palette.cream.opacity(0.68) : Palette.gold)
            }
        }
        .buttonStyle(.plain)
        .task(id: photo.developedImageName) {
            let name = photo.developedImageName ?? photo.rawImageName
            image = await PhotoThumbnailRepository.shared.image(named: name, maxPixelSize: 420)
        }
    }
}
