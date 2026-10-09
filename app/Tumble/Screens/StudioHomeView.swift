import AVFoundation
import PhotosUI
import SwiftUI
import TumbleAnalytics
import TumbleKit
import UIKit

struct StudioHomeView: View {
    @Environment(AppModel.self) private var app
    @AppStorage(FilmStockCatalog.storageKey) private var selectedStockID = FilmStockCatalog.defaultStock.id

    @State private var selectedItem: PhotosPickerItem?
    @State private var pendingIntent: HomeEditIntent?
    @State private var showPhotoPicker = false
    @State private var studioDraft: EditDraft?
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showIntroduction = false
    @State private var importInProgress = false
    @State private var message: String?

    var body: some View {
        ZStack {
            GraincoreBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    hero
                    if let draft = app.drafts.activeDraft { resumeCard(draft) }
                    filmCollection
                    postcardFeature
                    privacyLine
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)

            if importInProgress { importOverlay }
        }
        .background {
            // The picker is hosted on its own view, apart from the Studio
            // cover below.
            Color.clear
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        }
        .task {
            await app.startStore()
            TumbleAnalytics.shared.screen(.home)
            TumbleAnalytics.shared.capture(.homeViewed)
#if DEBUG
            if DebugLaunch.clearsDraft { await app.drafts.discard() }
            if DebugLaunch.opensSettings { showSettings = true }
            if ProcessInfo.processInfo.arguments.contains("-cameraDemo") { showCamera = true }
            if ProcessInfo.processInfo.arguments.contains("-studioDemo") || ProcessInfo.processInfo.arguments.contains("-finishDemo") {
                let data = DebugLaunch.demoImageData
                    ?? UIImage(named: "onboarding-editorial")?.jpegData(compressionQuality: 0.96)
                    ?? FilmScene.goldenHour.image(size: 1600).jpegData(compressionQuality: 0.96)
                if let data {
                    let demoStockID = DebugLaunch.value(for: "-demoStock") ?? selectedStockID
                    if var draft = try? await app.drafts.create(imageData: data, source: .library, stockID: demoStockID) {
                        if let crop = DebugLaunch.value(for: "-demoCrop"), let preset = CropPreset(rawValue: crop) {
                            draft.recipe.cropPreset = preset
                        }
                        if let frame = DebugLaunch.value(for: "-demoFrame"), PostcardFrameStyle(rawValue: frame) != nil {
                            draft.recipe.frameID = frame
                        }
                        if let note = DebugLaunch.value(for: "-demoNote") {
                            draft.recipe.note = note
                        }
                        if let degrees = DebugLaunch.value(for: "-demoStraighten").flatMap(Double.init) {
                            draft.recipe.straighten = degrees
                        }
                        app.drafts.update(draft.recipe)
                        studioDraft = app.drafts.activeDraft ?? draft
                    }
                }
            }
#endif
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
        .onChange(of: showPhotoPicker) { _, shown in
            if !shown, selectedItem == nil, !importInProgress { pendingIntent = nil }
        }
        .fullScreenCover(isPresented: $showCamera) {
            NeutralCameraView { data in
                showCamera = false
                Task { await createDraft(data: data, source: .camera) }
            }
            .repairingSafeArea()
        }
        .fullScreenCover(item: $studioDraft) { draft in
            StudioView(draft: draft) {
                selectedStockID = app.drafts.activeDraft?.recipe.stockID ?? selectedStockID
            }
            .environment(app)
        }
        .sheet(isPresented: $showSettings) {
            TumbleSettingsView(onReplayIntroduction: { showIntroduction = true }).environment(app)
        }
        .fullScreenCover(isPresented: $showIntroduction) {
            TumbleThreeOnboarding { showIntroduction = false }
                .repairingSafeArea()
        }
        .alert("Tumble", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) { Button("OK") { message = nil } } message: { Text(message ?? "") }
        .onOpenURL { url in
            guard url.scheme == "tumble", url.host == "camera" else { return }
            showCamera = true
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Tumble")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            IconButton("gearshape", accessibilityLabel: "Settings") { showSettings = true }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            BeforeAfterHero()

            VStack(alignment: .leading, spacing: 6) {
                Text("Find the film in your photos.")
                    .font(Typography.heroTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Choose a favorite, try 21 film looks on it, then finish it as a photo or a postcard.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button {
                    begin(HomeEditIntent(entryPoint: .primary, initialFilmID: selectedStockID))
                } label: {
                    Label("Choose a Photo", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    begin(HomeEditIntent(entryPoint: .camera, initialFilmID: selectedStockID))
                } label: {
                    Label("Take a Photo", systemImage: "camera")
                }
                .buttonStyle(SecondaryButtonStyle(height: 46))
            }
        }
    }

    private func resumeCard(_ draft: EditDraft) -> some View {
        Button { studioDraft = draft } label: {
            HStack(spacing: 14) {
                DraftThumbnail(draft: draft)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue your edit")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Text("\(draft.recipe.stock.name) · saved privately in Studio")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(12)
            .background(Palette.blueDeep.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var filmCollection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Film looks")
                        .font(Typography.title)
                        .foregroundStyle(Palette.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("21 looks")
                        .trackedLabel()
                        .foregroundStyle(Palette.amber)
                }
                Text("Original interpretations in four collections")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    homeFilmCard("fadedInstant", sample: "sample-coastal-drive")
                    homeFilmCard("disposable", sample: "sample-convenience-store")
                    homeFilmCard("silver", sample: "sample-sidewalk-cafe")
                    homeFilmCard("goldenHour", sample: "sample-beach-run")
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private func homeFilmCard(_ stockID: String, sample: String) -> some View {
        Button {
            begin(HomeEditIntent(entryPoint: .filmCard, initialFilmID: stockID))
        } label: {
            HomeFilmCard(stockID: stockID, sample: sample)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var postcardFeature: some View {
        Button {
            begin(HomeEditIntent(
                entryPoint: .postcardCard,
                initialFilmID: selectedStockID,
                intendedFormat: .postcard
            ))
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HomePostcardSample()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("A signature finish")
                        .font(Typography.title)
                        .foregroundStyle(Palette.textPrimary)
                    Text("Save a clean photograph, or turn it into a postcard with paper, frame, and a handwritten note.")
                        .font(Typography.body)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text("Make a postcard")
                        Image(systemName: "arrow.right")
                    }
                    .font(Typography.headline)
                    .foregroundStyle(Palette.amber)
                    .padding(.top, 4)
                }
            }
            .padding(18)
            .background(Palette.blueDeep.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var privacyLine: some View {
        Label("Photos stay on your device · No subscription", systemImage: "lock.shield")
            .font(Typography.caption)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity)
    }

    private var importOverlay: some View {
        ZStack {
            Color.black.opacity(0.56).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(Palette.amber)
                Text("Preparing your photo")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.textPrimary)
                Text("Copying it privately into Studio…")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .transition(.opacity)
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        importInProgress = true
        defer {
            selectedItem = nil
            importInProgress = false
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                TumbleAnalytics.shared.capture(.sourcePreparationFinished(source: "library", outcome: "failed", reason: "unreadable"))
                message = "That image could not be imported."
                return
            }
            await createDraft(data: data, source: .library)
        } catch {
            TumbleAnalytics.shared.capture(.sourcePreparationFinished(source: "library", outcome: "failed", reason: "load"))
            message = "That image could not be imported."
        }
    }

    private func createDraft(data: Data, source: EditSourceKind) async {
        do {
            let intent = pendingIntent ?? HomeEditIntent(entryPoint: .primary, initialFilmID: selectedStockID)
            let draft = try await app.drafts.create(imageData: data, source: source, recipe: intent.initialRecipe)
            TumbleAnalytics.shared.capture(.sourcePreparationFinished(source: source.rawValue, outcome: "completed", reason: nil))
            pendingIntent = nil
            studioDraft = draft
        } catch {
            TumbleAnalytics.shared.capture(.sourcePreparationFinished(source: source.rawValue, outcome: "failed", reason: "draft"))
            message = "Tumble could not create a private draft. Nothing was saved."
        }
    }

    private func begin(_ intent: HomeEditIntent) {
        pendingIntent = intent
        TumbleAnalytics.shared.capture(.homeEntrySelected(
            entryPoint: intent.entryPoint.rawValue,
            filmStockID: intent.entryPoint == .primary || intent.entryPoint == .camera ? nil : intent.initialFilmID,
            intendedFormat: intent.intendedFormat?.rawValue
        ))
        presentPendingIntent()
    }

    private func presentPendingIntent() {
        guard let pendingIntent else { return }
        switch pendingIntent.entryPoint {
        case .camera:
            TumbleAnalytics.shared.capture(.sourceSelected(source: EditSourceKind.camera.rawValue))
            showCamera = true
        case .primary, .filmCard, .postcardCard:
            TumbleAnalytics.shared.capture(.sourceSelected(source: EditSourceKind.library.rawValue))
            showPhotoPicker = true
        }
    }
}

private struct HomeFilmCard: View {
    let stockID: String
    let sample: String
    @State private var image: UIImage?

    private var stock: FilmStock { FilmStockCatalog.resolve(stockID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .frame(width: 188, height: 235)
                .overlay {
                    if let image { Image(uiImage: image).resizable().scaledToFill() }
                    else { Palette.blueDeep.overlay(ProgressView().tint(Palette.amber)) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.hairline))
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.textPrimary)
                Text(stock.blurb)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(width: 188, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Choose a photo to try this look")
        .task {
            let source = UIImage(named: sample) ?? UIImage(named: "onboarding-editorial") ?? FilmScene.warmPortrait.image(size: 480)
            let selectedStock = stock
            image = await Task.detached(priority: .utility) {
                TumblePhotoFilter.renderLivePreview(from: source, stock: selectedStock, maxDimension: 520)
            }.value
        }
    }
}

/// The neutral editorial sample split down the middle: as shot on the left,
/// with a film look on the right. Drag the divider to compare.
private struct BeforeAfterHero: View {
    @State private var original: UIImage? = UIImage(named: "onboarding-editorial")
    @State private var film: UIImage?
    @State private var split: CGFloat = 0.5
    private let stock = FilmStockCatalog.resolve("fadedInstant")

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                layer(film ?? original)
                layer(original)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: width * split)
                    }
                Rectangle()
                    .fill(Palette.cream)
                    .frame(width: 2)
                    .shadow(color: .black.opacity(0.35), radius: 3)
                    .overlay {
                        Circle()
                            .fill(Palette.cream)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "arrow.left.and.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 1)
                    }
                    .offset(x: width * split - 1)
            }
            .overlay(alignment: .bottomLeading) { tag("Original").padding(12) }
            .overlay(alignment: .bottomTrailing) { tag(stock.name).padding(12) }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        split = min(0.94, max(0.06, value.location.x / max(1, width)))
                    }
            )
        }
        .aspectRatio(1.05, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.hairline))
        .accessibilityElement()
        .accessibilityLabel("Example photo, original and \(stock.name)")
        .accessibilityValue("\(Int((split * 100).rounded())) percent original")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: split = min(0.94, split + 0.1)
            case .decrement: split = max(0.06, split - 0.1)
            @unknown default: break
            }
        }
        .task {
            guard film == nil, let source = original else { return }
            let selectedStock = stock
            film = await Task.detached(priority: .userInitiated) {
                TumblePhotoFilter.renderLivePreview(from: source, stock: selectedStock, maxDimension: 900)
            }.value
        }
    }

    private func layer(_ image: UIImage?) -> some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Palette.blueDeep
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .trackedLabel()
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(.black.opacity(0.55), in: Capsule())
    }
}

/// A finished postcard made from a bundled sample with a real film look.
private struct HomePostcardSample: View {
    @State private var image: UIImage?
    private let width: CGFloat = 236

    var body: some View {
        Group {
            if let image {
                PostcardFrameView(
                    style: .classicInstant,
                    image: image,
                    note: "Wish you were here",
                    seed: 31,
                    width: width
                )
            } else {
                RoundedRectangle(cornerRadius: 6).fill(Palette.printStock.opacity(0.2))
            }
        }
        .frame(width: width, height: width * PostcardFrameStyle.classicInstant.renderAspect(hasNote: true))
        .rotationEffect(.degrees(-3))
        .accessibilityHidden(true)
        .task {
            guard image == nil else { return }
            let source = UIImage(named: "sample-rainy-crosswalk") ?? FilmScene.pinkDusk.image(size: 480)
            let stock = FilmStockCatalog.resolve("goldenHour")
            image = await Task.detached(priority: .utility) {
                TumblePhotoFilter.renderLivePreview(from: source, stock: stock, maxDimension: 520)
            }.value
        }
    }
}

/// The active draft's photo, rendered with its current recipe.
private struct DraftThumbnail: View {
    @Environment(AppModel.self) private var app
    let draft: EditDraft
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Palette.surfaceRaised }
        }
        .accessibilityHidden(true)
        .task(id: draft.id) {
            guard let data = await app.drafts.sourceData(for: draft) else { return }
            let recipe = draft.recipe
            let capturedAt = draft.capturedAt
            image = await Task.detached(priority: .utility) {
                TumblePhotoFilter.renderEditedPreview(from: data, recipe: recipe, capturedAt: capturedAt, maxDimension: 180)
            }.value
        }
    }
}

private struct NeutralCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraController()
    @State private var permission = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var busy = false
    @State private var message: String?

    let onCapture: (Data) -> Void

    var body: some View {
        ZStack {
            EditorBackground()
            VStack(spacing: 14) {
                EditorTopBar(title: "Take a Photo") {
                    IconButton("xmark", accessibilityLabel: "Close camera") { dismiss() }
                } trailing: {
                    IconButton(
                        camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill",
                        accessibilityLabel: camera.flashMode == .on ? "Flash on" : "Flash off"
                    ) { camera.toggleFlash() }
                    .disabled(!camera.supportsFlash)
                }

                ZStack {
                    if permission == .authorized {
                        LiveFilmCameraPreview(session: camera.session, renderer: camera.previewRenderer)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 42, weight: .light))
                                .foregroundStyle(Palette.gold)
                            Text(permission == .denied ? "Camera access is off" : "Camera access is needed to take a photo")
                                .font(Typography.headline)
                                .multilineTextAlignment(.center)
                            if permission == .denied {
                                Button("Open Settings") { openSettings() }
                                    .foregroundStyle(Palette.gold)
                            }
                        }
                        .foregroundStyle(Palette.cream)
                        .padding(24)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Palette.hairline))
                .aspectRatio(3 / 4, contentMode: .fit)
                .padding(.horizontal, 16)

                HStack {
                    Color.clear.frame(width: 60)
                    Spacer()
                    Button { capture() } label: {
                        ZStack {
                            Circle().stroke(Palette.cream, lineWidth: 4).frame(width: 78, height: 78)
                            Circle().fill(Palette.cream).frame(width: 64, height: 64)
                            if busy { ProgressView().tint(Palette.ink) }
                        }
                    }
                    .disabled(permission != .authorized || busy)
                    .accessibilityLabel("Take photo")
                    Spacer()
                    Button { camera.switchCamera() } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Palette.cream)
                            .frame(width: 60)
                    }
                    .disabled(!camera.canSwitchCameras || permission != .authorized)
                }
                .padding(.bottom, 18)
            }
        }
        .task { requestCamera() }
        .onDisappear {
            camera.stop()
            TumbleAnalytics.shared.resumeReplay()
        }
        .alert("Tumble", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) { Button("OK") { message = nil } } message: { Text(message ?? "") }
    }

    private func requestCamera() {
        switch permission {
        case .authorized:
            startCamera()
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                permission = granted ? .authorized : .denied
                TumbleAnalytics.shared.capture(.permissionResponded(permission: "camera", outcome: granted ? "granted" : "denied", context: "capture_utility"))
                if granted { startCamera() }
            }
        default:
            permission = .denied
        }
    }

    private func startCamera() {
        camera.previewStock = FilmStockCatalog.resolve("original")
        camera.previewIntensity = 0
        camera.start()
        TumbleAnalytics.shared.screen(.camera)
        TumbleAnalytics.shared.pauseReplay()
    }

    private func capture() {
        Haptics.soft()
        busy = true
        camera.captureResult { result in
            busy = false
            switch result {
            case .success(let photo): onCapture(photo.data)
            case .unavailable(let reason):
                TumbleAnalytics.shared.capture(.sourcePreparationFinished(source: "camera", outcome: "failed", reason: "unavailable"))
                message = reason
            case .failure(let reason, _):
                TumbleAnalytics.shared.capture(.sourcePreparationFinished(source: "camera", outcome: "failed", reason: "capture"))
                message = reason
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
