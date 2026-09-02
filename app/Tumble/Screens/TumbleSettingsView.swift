import SwiftData
import SwiftUI
import TumbleAnalytics
import TumbleKit

struct TumbleSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Query private var legacyPhotos: [Photo]
    @State private var analyticsEnabled = false
    @State private var showLegacy = false
    @State private var showComplete = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraincoreBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        settingCard {
                            Toggle(isOn: Binding(
                                get: { analyticsEnabled },
                                set: { value in
                                    analyticsEnabled = value
                                    TumbleAnalytics.shared.setEnabled(value)
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Help improve Tumble")
                                        .font(Typography.sans(15, weight: .semibold))
                                    Text("Anonymous events, crashes and masked replay. Off by default.")
                                        .font(Typography.sans(12))
                                        .foregroundStyle(Palette.cream.opacity(0.58))
                                }
                            }
                            .tint(Palette.gold)
                        }

                        Button { showComplete = true } label: {
                            settingRow("Tumble Complete", detail: "Unlock all fifteen premium films", icon: "camera.filters")
                        }
                        .buttonStyle(.plain)

                        if !legacyPhotos.isEmpty {
                            Button { showLegacy = true } label: {
                                settingRow(
                                    "Legacy Drawer",
                                    detail: "\(legacyPhotos.count) saved \(legacyPhotos.count == 1 ? "print" : "prints")",
                                    icon: "archivebox"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Link(destination: URL(string: "https://gettumbleapp.com/privacy")!) {
                            settingRow("Privacy policy", detail: "How local processing and optional analytics work", icon: "lock.shield")
                        }
                        Link(destination: URL(string: "mailto:aftaab@aftaab.dev?subject=Tumble%203")!) {
                            settingRow("Support", detail: "Contact the developer", icon: "envelope")
                        }

                        Text("Tumble \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0")")
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
        .fullScreenCover(isPresented: $showLegacy) { LegacyDrawerView().environment(app) }
        .sheet(isPresented: $showComplete) { CompletePaywallView().environment(app) }
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

private struct LegacyDrawerView: View {
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
                        Text("Legacy Drawer").font(Typography.display(28)).foregroundStyle(Palette.cream)
                        Text("Your prints from Tumble 2")
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
                                LegacyPrintTile(photo: photo) {
                                    if !photo.isDeveloped { finish(photo) }
                                    selected = photo
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

    private func finish(_ photo: Photo) {
        guard let raw = PhotoStore.loadImageData(named: photo.rawImageName),
              let rendered = TumblePhotoFilter.renderMemoryPhotoData(
                from: raw,
                grade: photo.filmStock.grade,
                capturedAt: photo.capturedAt
              ) else { return }
        photo.developedImageName = try? PhotoStore.writeImage(rendered, id: photo.id, kind: .developed)
        photo.developProgress = 1
        photo.isDeveloped = true
        try? context.save()
    }
}

private struct LegacyPrintTile: View {
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
            image = PhotoStore.loadImageData(named: name).flatMap(UIImage.init(data:))
        }
    }
}
