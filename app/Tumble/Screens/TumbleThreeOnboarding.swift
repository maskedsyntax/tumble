import SwiftUI
import TumbleAnalytics
import TumbleKit

/// A permission-free sample of the complete Tumble journey. The sample never
/// enters the draft store and nothing is captured before analytics consent.
struct TumbleThreeOnboarding: View {
    let onDone: () -> Void

    @State private var stockID = FilmStockCatalog.defaultStock.id
    @State private var showingOriginal = false
    @State private var postcard = false
    @State private var rendered: UIImage?
    @State private var showAnalyticsChoice = false

    private let source = UIImage(named: "onboarding-editorial") ?? FilmScene.warmPortrait.image(size: 1200)
    private let sampleStocks = ["fadedInstant", "disposable", "goldenHour"]

    private var stock: FilmStock { FilmStockCatalog.resolve(stockID) }
    private var sourceData: Data? { source.jpegData(compressionQuality: 0.94) }

    var body: some View {
        ZStack {
            GraincoreBackground()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 5) {
                        Text("Tumble")
                            .font(Typography.display(38))
                            .foregroundStyle(Palette.cream)
                        Text("Give your photos the character of film.")
                            .font(Typography.display(24))
                            .foregroundStyle(Palette.cream)
                            .multilineTextAlignment(.center)
                        Text("Try a film, compare the original, then finish it as a photo or postcard.")
                            .font(Typography.sans(14))
                            .foregroundStyle(Palette.cream.opacity(0.66))
                            .multilineTextAlignment(.center)
                    }

                    samplePreview

                    HStack(spacing: 8) {
                        ForEach(sampleStocks, id: \.self) { id in
                            let choice = FilmStockCatalog.resolve(id)
                            Button(choice.name) {
                                stockID = id
                                showingOriginal = false
                            }
                            .font(Typography.sans(11, weight: .bold))
                            .foregroundStyle(stockID == id ? Palette.ink : Palette.cream)
                            .padding(.horizontal, 13)
                            .frame(height: 38)
                            .background(stockID == id ? Palette.gold : Palette.cream.opacity(0.09), in: Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        formatButton("Photo", icon: "photo", selected: !postcard) { postcard = false }
                        formatButton("Postcard", icon: "rectangle.portrait", selected: postcard) { postcard = true }
                    }

                    VStack(spacing: 10) {
                        Button { showAnalyticsChoice = true } label: {
                            Label("Start with my photo", systemImage: "photo.on.rectangle.angled")
                                .font(Typography.sans(16, weight: .bold))
                                .foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Palette.gold, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Label("Edit without an account · Photos stay on device", systemImage: "lock.shield")
                            .font(Typography.sans(11, weight: .semibold))
                            .foregroundStyle(Palette.cream.opacity(0.52))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
        }
        .task(id: stockID) { await renderSample() }
        .alert("Help improve Tumble?", isPresented: $showAnalyticsChoice) {
            Button("Allow anonymous analytics") {
                TumbleAnalytics.shared.setEnabled(true)
                onDone()
            }
            Button("Not now", role: .cancel) { onDone() }
        } message: {
            Text("Share anonymous product events, crash diagnostics, and masked session replay. Photo pixels, filenames, edits, and notes are never sent. You can change this in Settings.")
        }
    }

    private var samplePreview: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black.opacity(0.28)
                let image = showingOriginal ? source : (rendered ?? source)
                if postcard {
                    PostcardFrameView(
                        style: .classicInstant,
                        image: image,
                        note: "September light",
                        capturedAt: Date(timeIntervalSince1970: 1_757_865_600),
                        seed: 31,
                        width: 286
                    )
                    .aspectRatio(1 / PostcardFrameStyle.classicInstant.aspect, contentMode: .fit)
                    .padding(16)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(10)
                }
            }
            .frame(height: 330)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(showingOriginal ? "ORIGINAL" : "FILM CHARACTER")
                        .font(Typography.sans(9, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Palette.cream.opacity(0.48))
                    Text(showingOriginal ? "Source photo" : stock.name)
                        .font(Typography.sans(13, weight: .bold))
                        .foregroundStyle(Palette.cream)
                }
                Spacer()
                Button(showingOriginal ? "Show Film" : "Compare Original") {
                    showingOriginal.toggle()
                }
                .font(Typography.sans(11, weight: .bold))
                .foregroundStyle(Palette.gold)
            }
            .padding(14)
            .background(Palette.charcoalDeep.opacity(0.82))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.cream.opacity(0.08)))
    }

    private func formatButton(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(Typography.sans(13, weight: .bold))
                .foregroundStyle(selected ? Palette.ink : Palette.cream)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(selected ? Palette.gold : Palette.cream.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }

    private func renderSample() async {
        guard let sourceData else { return }
        let recipe = EditRecipe(stockID: stockID)
        let image = await Task.detached(priority: .userInitiated) {
            TumblePhotoFilter.renderEditedPreview(
                from: sourceData,
                recipe: recipe,
                capturedAt: Date(timeIntervalSince1970: 1_757_865_600),
                maxDimension: 900
            )
        }.value
        guard !Task.isCancelled, recipe.stockID == stockID else { return }
        rendered = image
    }
}
