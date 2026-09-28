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
                VStack(alignment: .leading, spacing: 20) {
                    header
                    hero
                    if let draft = app.drafts.activeDraft { resumeCard(draft) }
                    filmCollection
                    postcardFeature
                    privacyLine
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }

            if importInProgress { importOverlay }
        }
        .task {
            await app.startStore()
            TumbleAnalytics.shared.screen(.home)
            TumbleAnalytics.shared.capture(.homeViewed)
#if DEBUG
            if DebugLaunch.clearsDraft { await app.drafts.discard() }
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
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            NeutralCameraView { data in
                showCamera = false
                Task { await createDraft(data: data, source: .camera) }
            }
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tumble")
                    .font(Typography.display(34))
                    .foregroundStyle(Palette.cream)
                Text("VINTAGE PHOTO STUDIO")
                    .font(Typography.sans(9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.gold)
            }
            Spacer()
            Button { showSettings = true } label: {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.28))
                        .frame(
                            width: EditorChromeMetrics.topBarControlVisual,
                            height: EditorChromeMetrics.topBarControlVisual
                        )
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                }
                .frame(
                    width: EditorChromeMetrics.minimumHitTarget,
                    height: EditorChromeMetrics.minimumHitTarget
                )
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Give your photos\nthe character of film.")
                    .font(Typography.display(34))
                    .foregroundStyle(Palette.cream)
                Text("Start with a favorite, find its film character, then finish it as a photo or postcard.")
                    .font(Typography.sans(14))
                    .foregroundStyle(Palette.cream.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                begin(HomeEditIntent(entryPoint: .primary, initialFilmID: selectedStockID))
            } label: {
                Label("Choose a Photo", systemImage: "photo.on.rectangle.angled")
                    .font(Typography.sans(15, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Palette.gold, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                begin(HomeEditIntent(entryPoint: .camera, initialFilmID: selectedStockID))
            } label: {
                Label("Take a Photo", systemImage: "camera")
                    .font(Typography.sans(13, weight: .bold))
                    .foregroundStyle(Palette.cream)
                    .frame(maxWidth: .infinity)
                    .frame(height: EditorChromeMetrics.minimumHitTarget)
                    .background(Palette.cream.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.cream.opacity(0.10)))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Palette.charcoalDeep.opacity(0.96), Palette.blueDeep.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.gold.opacity(0.18)))
    }

    private func resumeCard(_ draft: EditDraft) -> some View {
        Button { studioDraft = draft } label: {
            HStack(spacing: 11) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue your edit")
                        .font(Typography.sans(15, weight: .bold))
                    Text("Your private draft is waiting in Studio.")
                        .font(Typography.sans(11))
                        .foregroundStyle(Palette.cream.opacity(0.58))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(Palette.gold)
            }
            .foregroundStyle(Palette.cream)
            .padding(14)
            .background(Palette.charcoalDeep.opacity(0.68), in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }

    private var filmCollection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Find its film character")
                        .font(Typography.display(24))
                        .foregroundStyle(Palette.cream)
                    Text("21 original interpretations across four collections")
                        .font(Typography.sans(11))
                        .foregroundStyle(Palette.cream.opacity(0.54))
                }
                Spacer()
                Text("21 LOOKS")
                    .font(Typography.sans(9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Palette.gold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    homeFilmCard("fadedInstant", scene: .warmPortrait)
                    homeFilmCard("disposable", scene: .blueHourRooftop)
                    homeFilmCard("silver", scene: .sunlitPark)
                    homeFilmCard("goldenHour", scene: .beachMorning)
                }
            }
        }
    }

    private func homeFilmCard(_ stockID: String, scene: FilmScene) -> some View {
        Button {
            begin(HomeEditIntent(entryPoint: .filmCard, initialFilmID: stockID))
        } label: {
            HomeFilmCard(stockID: stockID, scene: scene)
        }
        .buttonStyle(.plain)
    }

    private var postcardFeature: some View {
        Button {
            begin(HomeEditIntent(
                entryPoint: .postcardCard,
                initialFilmID: selectedStockID,
                intendedFormat: .postcard
            ))
        } label: {
        VStack(alignment: .leading, spacing: 12) {
            PostcardFrameView(
                style: .classicInstant,
                image: FilmScene.pinkDusk.image(size: 420),
                note: "Wish you were here",
                seed: 31,
                width: 248
            )
            .frame(
                width: 248,
                height: 248 * PostcardFrameStyle.classicInstant.renderAspect(hasNote: true)
            )
            .frame(maxWidth: .infinity)
            .rotationEffect(.degrees(-3))

            VStack(alignment: .leading, spacing: 6) {
                Text("A signature finish")
                    .font(Typography.display(22))
                    .foregroundStyle(Palette.cream)
                Text("Save a clean photograph—or turn it into a personal postcard with paper, frame, and a handwritten note.")
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.62))
                Label("Choose a photo for a postcard", systemImage: "arrow.right")
                    .font(Typography.sans(12, weight: .bold))
                    .foregroundStyle(Palette.gold)
            }
        }
        .padding(15)
        .background(Palette.charcoalDeep.opacity(0.58), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var privacyLine: some View {
        Label("Photos stay on device · No subscription", systemImage: "lock.shield")
            .font(Typography.sans(11, weight: .semibold))
            .foregroundStyle(Palette.cream.opacity(0.48))
            .frame(maxWidth: .infinity)
    }

    private var importOverlay: some View {
        ZStack {
            Color.black.opacity(0.56).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().controlSize(.large).tint(Palette.gold)
                Text("Preparing your photo")
                    .font(Typography.display(22))
                    .foregroundStyle(Palette.cream)
                Text("Copying it privately into Studio…")
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.62))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Palette.blueDeep.opacity(0.96), in: RoundedRectangle(cornerRadius: 24))
        }
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
    let scene: FilmScene
    @State private var image: UIImage?

    private var stock: FilmStock { FilmStockCatalog.resolve(stockID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                if let image { Image(uiImage: image).resizable().scaledToFill() }
                else { Color.black.opacity(0.24).overlay(ProgressView().tint(Palette.gold)) }
            }
            .frame(width: 216, height: 146)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14))
            Text(stock.name)
                .font(Typography.sans(12, weight: .bold))
                .foregroundStyle(Palette.cream)
            Text(stock.blurb)
                .font(Typography.sans(9))
                .foregroundStyle(Palette.cream.opacity(0.52))
                .lineLimit(1)
        }
        .frame(width: 216, alignment: .leading)
        .task {
            let source = UIImage(named: "onboarding-editorial") ?? scene.image(size: 480)
            let selectedStock = stock
            image = await Task.detached(priority: .utility) {
                TumblePhotoFilter.renderLivePreview(from: source, stock: selectedStock, maxDimension: 360)
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
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.42), in: Circle())
                    }
                    Spacer()
                    Text("Take a Photo")
                        .font(Typography.display(23))
                    Spacer()
                    Button { camera.toggleFlash() } label: {
                        Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.42), in: Circle())
                    }
                    .disabled(!camera.supportsFlash)
                }
                .foregroundStyle(Palette.cream)
                .padding(.horizontal, 16)

                ZStack {
                    if permission == .authorized {
                        LiveFilmCameraPreview(session: camera.session, renderer: camera.previewRenderer)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 42, weight: .light))
                                .foregroundStyle(Palette.gold)
                            Text(permission == .denied ? "Camera access is off" : "Camera access is needed to take a photo")
                                .font(Typography.display(21))
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
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Palette.cream.opacity(0.12)))
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
