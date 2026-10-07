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
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text("Tumble")
                            .trackedLabel()
                            .foregroundStyle(Palette.amber)
                        Text("Give your photos the character of film.")
                            .font(Typography.heroTitle)
                            .foregroundStyle(Palette.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Try a film, compare the original, then finish it as a photo or postcard.")
                            .font(Typography.body)
                            .foregroundStyle(Palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    samplePreview

                    HStack(spacing: 8) {
                        ForEach(sampleStocks, id: \.self) { id in
                            Chip(title: FilmStockCatalog.resolve(id).name, selected: stockID == id) {
                                Haptics.selection()
                                stockID = id
                                showingOriginal = false
                            }
                        }
                    }

                    SegmentedPill(
                        options: [false, true],
                        selection: postcard,
                        title: { $0 ? "Postcard" : "Photo" },
                        icon: { $0 ? "rectangle.portrait.on.rectangle.portrait" : "photo" }
                    ) { postcard = $0 }

                    VStack(spacing: 12) {
                        Button { showAnalyticsChoice = true } label: {
                            Label("Start with my photo", systemImage: "photo.on.rectangle.angled")
                        }
                        .buttonStyle(PrimaryButtonStyle(height: 54))

                        Label("Edit without an account · Photos stay on device", systemImage: "lock.shield")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .animation(Motion.fade, value: postcard)
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
        let image = showingOriginal ? source : (rendered ?? source)
        return ZStack {
            Palette.canvas.opacity(0.55)
            if postcard {
                PostcardFrameView(
                    style: .classicInstant,
                    image: image,
                    note: "September light",
                    capturedAt: Date(timeIntervalSince1970: 1_757_865_600),
                    seed: 31,
                    width: 260
                )
                .aspectRatio(1 / PostcardFrameStyle.classicInstant.aspect, contentMode: .fit)
                .padding(18)
                .transition(.opacity)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.hairline))
        .overlay(alignment: .bottom) {
            HStack {
                Text(showingOriginal ? "Original" : stock.name)
                    .trackedLabel()
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(.black.opacity(0.55), in: Capsule())
                Spacer()
                Button(showingOriginal ? "Show Film" : "Compare Original") {
                    Haptics.selection()
                    showingOriginal.toggle()
                }
                .font(Typography.captionEmphasized)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Palette.cream, in: Capsule())
                .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
            }
            .padding(10)
        }
        .animation(Motion.fade, value: showingOriginal)
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
