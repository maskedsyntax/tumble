import AVFoundation
import PhotosUI
import SwiftUI
import TumbleAnalytics
import TumbleKit
import UIKit

struct CameraWorkspace: View {
    @Environment(AppModel.self) private var app
    @StateObject private var camera = CameraController()
    @AppStorage("tumble.v3.analyticsPromptShown") private var analyticsPromptShown = false
    @AppStorage(FilmStockCatalog.storageKey) private var selectedStockID = FilmStockCatalog.defaultStock.id

    @State private var permission = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var studioDraft: EditDraft?
    @State private var showSettings = false
    @State private var showDrawer = false
    @State private var showComplete = false
    @State private var showResume = false
    @State private var showAnalyticsOffer = false
    @State private var captureInProgress = false
    @State private var importInProgress = false
    @State private var centeredStockID: String?
    @State private var filmRailIsScrolling = false
    @State private var message: String?

    private var selectedStock: FilmStock { FilmStockCatalog.resolve(selectedStockID) }

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 12) {
                header
                viewfinder
                filmSelector
                cameraControls
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if importInProgress {
                importProgressOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }
#if DEBUG
            if DebugLaunch.opensSettings {
                TumbleSettingsView().environment(app).zIndex(100)
            } else if DebugLaunch.opensAccount {
                AccountView()
                    .environment(app)
                    .safeAreaPadding(.top, 42)
                    .background(GraincoreBackground())
                    .zIndex(100)
            }
#endif
        }
        .task { await app.startStore() }
        .task {
#if DEBUG
            if DebugLaunch.clearsDraft {
                await app.drafts.discard()
            }
            if DebugLaunch.opensPhotoPicker {
                try? await Task.sleep(for: .milliseconds(350))
                showPhotoPicker = true
            }
#endif
            permission = AVCaptureDevice.authorizationStatus(for: .video)
            if permission == .authorized { startCamera() }
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-studioDemo"),
               let data = DebugLaunch.demoImageData
                    ?? FilmScene.goldenHour.image(size: 1400).jpegData(compressionQuality: 0.96),
               var draft = try? await app.drafts.create(imageData: data, source: .camera, stockID: selectedStockID) {
                var recipe = draft.recipe
                if let stockID = DebugLaunch.value(for: "-demoStock") {
                    recipe.stockID = stockID
                }
                if let crop = DebugLaunch.value(for: "-demoCrop"),
                   let preset = CropPreset(rawValue: crop) {
                    recipe.cropPreset = preset
                }
                if let frame = DebugLaunch.value(for: "-demoFrame"),
                   PostcardFrameStyle(rawValue: frame) != nil {
                    recipe.frameID = frame
                }
                if let note = DebugLaunch.value(for: "-demoNote") {
                    recipe.note = PostcardNote.clamp(note.replacingOccurrences(of: "_", with: " "))
                }
                draft.recipe = recipe
                app.drafts.update(recipe)
                studioDraft = draft
                return
            }
#endif
            if app.drafts.activeDraft != nil { showResume = true }
        }
        .onChange(of: selectedStockID) { _, _ in updatePreviewFilm() }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            withAnimation(.easeOut(duration: 0.18)) { importInProgress = true }
            Task { await importPhoto(item) }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onDisappear { camera.stop() }
        .fullScreenCover(item: $studioDraft) { draft in
            StudioView(draft: draft) { firstSaveCompleted() }.environment(app)
        }
        .fullScreenCover(isPresented: $showDrawer) { DrawerLibraryView().environment(app) }
        .sheet(isPresented: $showSettings) { TumbleSettingsView().environment(app) }
        .sheet(isPresented: $showComplete) { CompletePaywallView().environment(app) }
        .confirmationDialog("Continue your last edit?", isPresented: $showResume, titleVisibility: .visible) {
            Button("Continue editing") { studioDraft = app.drafts.activeDraft }
            Button("Discard draft", role: .destructive) { Task { await app.drafts.discard() } }
        } message: {
            Text("Tumble kept one private draft on this device because it was not saved yet.")
        }
        .alert("Help improve Tumble?", isPresented: $showAnalyticsOffer) {
            Button("Allow anonymous analytics") {
                analyticsPromptShown = true
                TumbleAnalytics.shared.setEnabled(true)
            }
            Button("Not now", role: .cancel) { analyticsPromptShown = true }
        } message: {
            Text("Share anonymous product events, crash diagnostics, and masked session replay. Photo pixels, filenames, edits, and notes are never sent. You can change this in Settings.")
        }
        .alert("Tumble", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) { Button("OK") { message = nil } } message: { Text(message ?? "") }
        .onOpenURL { url in
            guard url.scheme == "tumble", url.host == "camera" else { return }
            requestCameraIfNeeded()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Tumble").font(Typography.display(28)).foregroundStyle(Palette.cream)
                Text(selectedStock.name).font(Typography.sans(12, weight: .semibold)).foregroundStyle(Palette.gold)
            }
            Spacer()
            HStack(spacing: 9) {
                Button { showDrawer = true } label: {
                    Label("Drawer", systemImage: "rectangle.stack.fill")
                        .font(Typography.sans(12, weight: .bold))
                        .foregroundStyle(Palette.cream)
                        .padding(.horizontal, 13)
                        .frame(height: 42)
                        .background(.black.opacity(0.28), in: Capsule())
                }
                .buttonStyle(.plain)

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
    }

    private var viewfinder: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.black)
                if let demoImage = cameraDemoImage {
                    Image(uiImage: demoImage)
                        .resizable()
                        .scaledToFill()
                } else if permission == .authorized {
                    LiveFilmCameraPreview(
                        session: camera.session,
                        renderer: camera.previewRenderer
                    )
                } else {
                    permissionPlaceholder
                }
                LinearGradient(colors: [.black.opacity(0.24), .clear, .black.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)
                VStack {
                    HStack {
                        Button { camera.toggleFlash() } label: {
                            Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                        }
                        .disabled(!camera.supportsFlash)
                        Spacer()
                        Text("LIVE FILM")
                            .font(Typography.sans(10, weight: .bold)).tracking(1.3)
                    }
                    Spacer()
                }
                .foregroundStyle(Palette.cream)
                .padding(18)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Palette.cream.opacity(0.12)))
            .contentShape(RoundedRectangle(cornerRadius: 28))
            .onTapGesture { requestCameraIfNeeded() }
        }
        // The product is portrait-only; keeping the viewfinder explicitly at
        // the camera's 3:4 ratio avoids an accidental landscape workspace on
        // devices whose available-height proposal changes during startup.
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .frame(maxHeight: .infinity)
    }

    private var cameraDemoImage: UIImage? {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-cameraDemo"),
              let data = DebugLaunch.demoImageData else { return nil }
        return UIImage(data: data)
        #else
        return nil
        #endif
    }

    @ViewBuilder private var permissionPlaceholder: some View {
        VStack(spacing: 13) {
            Image(systemName: permission == .denied ? "camera.fill.badge.ellipsis" : "camera.aperture")
                .font(.system(size: 42, weight: .light)).foregroundStyle(Palette.gold)
            Text(permission == .denied ? "Camera access is off" : "Tap to use the camera")
                .font(Typography.display(22)).foregroundStyle(Palette.cream)
            Text("Import always works without camera access.")
                .font(Typography.sans(12)).foregroundStyle(Palette.cream.opacity(0.62))
            if permission == .denied {
                Button("Open Settings") { openSystemSettings() }
                    .font(Typography.sans(13, weight: .bold)).foregroundStyle(Palette.gold)
            }
        }
    }

    private var filmSelector: some View {
        GeometryReader { proxy in
            let itemWidth = min(148, max(124, proxy.size.width * 0.38))
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(FilmStockCatalog.all) { stock in
                        let unlocked = app.purchases.isUnlocked(stock)
                        let centered = centeredStockID == stock.id
                        Button {
                            guard unlocked else {
                                showComplete = true
                                return
                            }
                            // Apply the film on the first tap instead of waiting
                            // for the rail's centering animation to finish.
                            selectStockImmediately(stock)
                            if !centered {
                                withAnimation(.snappy(duration: 0.20)) { centeredStockID = stock.id }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 5) {
                                    Text(stock.name)
                                        .lineLimit(1)
                                    if !unlocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                }
                                .font(Typography.sans(12, weight: centered ? .bold : .semibold))
                                .foregroundStyle(centered ? Palette.gold : Palette.cream.opacity(0.62))

                                Text(FilmStockCatalog.pack(for: stock.packID)?.name.uppercased() ?? "FILM")
                                    .font(Typography.sans(7, weight: .bold))
                                    .tracking(0.9)
                                    .foregroundStyle(Palette.cream.opacity(centered ? 0.52 : 0.30))

                                Capsule()
                                    .fill(centered ? Palette.gold : Palette.cream.opacity(0.16))
                                    .frame(width: centered ? 34 : 14, height: 2)
                            }
                            .frame(width: itemWidth, height: 56)
                            .background(
                                centered ? Palette.charcoalDeep.opacity(0.48) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(centered ? Palette.gold.opacity(0.34) : Color.clear)
                            }
                            .scaleEffect(centered ? 1 : 0.94)
                            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .id(stock.id)
                        .accessibilityLabel("\(stock.name) film\(unlocked ? "" : ", locked")")
                        .accessibilityAddTraits(centered ? .isSelected : [])
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, max(0, (proxy.size.width - itemWidth) / 2), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centeredStockID, anchor: .center)
            .onAppear {
                centeredStockID = selectedStockID
            }
            .onChange(of: centeredStockID) { _, id in
                if !filmRailIsScrolling { selectCenteredStock(id) }
            }
            .onScrollPhaseChange { _, phase in
                filmRailIsScrolling = phase != .idle
                if phase == .idle { selectCenteredStock(centeredStockID) }
            }
        }
        .frame(height: 60)
    }

    private var cameraControls: some View {
        HStack {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                controlIcon("photo.on.rectangle", label: "Import")
            }
            Spacer()
            Button { capture() } label: {
                ZStack {
                    Circle().stroke(Palette.cream, lineWidth: 4).frame(width: 76, height: 76)
                    Circle().fill(captureInProgress ? Palette.cream.opacity(0.45) : Palette.cream).frame(width: 62, height: 62)
                }
            }
            .disabled(captureInProgress || permission != .authorized)
            .accessibilityLabel("Take photo")
            Spacer()
            Button { camera.switchCamera() } label: {
                controlIcon("camera.rotate.fill", label: "Flip")
            }
            .disabled(!camera.canSwitchCameras || permission != .authorized)
        }
        .frame(height: 82)
    }

    nonisolated private func controlIcon(_ name: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: name).font(.system(size: 21, weight: .semibold))
            Text(label).font(Typography.sans(10, weight: .semibold))
        }
        .foregroundStyle(Palette.cream)
        .frame(width: 62)
    }

    private func requestCameraIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permission = .authorized
            startCamera()
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                permission = granted ? .authorized : .denied
                TumbleAnalytics.shared.capture(.permissionResponded(permission: "camera", outcome: granted ? "granted" : "denied", context: "camera_workspace"))
                if granted { startCamera() }
            }
        case .denied, .restricted:
            permission = .denied
        @unknown default:
            permission = .denied
        }
    }

    private func startCamera() {
        updatePreviewFilm()
        camera.start()
        TumbleAnalytics.shared.pauseReplay()
    }

    private func updatePreviewFilm() {
        camera.previewStock = selectedStock
        camera.previewIntensity = 1
    }

    private func capture() {
        guard !captureInProgress else { return }
        captureInProgress = true
        camera.captureResult { result in
            switch result {
            case .success(let photo):
                Task {
                    await createDraft(data: photo.data, source: .camera)
                    captureInProgress = false
                }
            case .unavailable(let reason):
                captureInProgress = false
                message = reason
            case .failure(let reason, _):
                captureInProgress = false
                message = reason
            }
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        defer {
            selectedItem = nil
            withAnimation(.easeOut(duration: 0.16)) { importInProgress = false }
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                message = "That image could not be imported."
                return
            }
            await createDraft(data: data, source: .library)
        } catch {
            message = "That image could not be imported."
        }
    }

    private var importProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.54).ignoresSafeArea()
            VStack(spacing: 13) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Palette.gold)
                Text("Preparing your photo")
                    .font(Typography.display(22))
                    .foregroundStyle(Palette.cream)
                Text("Copying it privately into Studio…")
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.62))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Palette.cream.opacity(0.10))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your photo for Studio")
    }

    private func selectCenteredStock(_ id: String?) {
        guard let id, id != selectedStockID else { return }
        let stock = FilmStockCatalog.resolve(id)
        guard app.purchases.isUnlocked(stock) else {
            showComplete = true
            withAnimation(.snappy(duration: 0.24)) { centeredStockID = selectedStockID }
            return
        }
        selectedStockID = stock.id
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func selectStockImmediately(_ stock: FilmStock) {
        guard stock.id != selectedStockID else { return }
        selectedStockID = stock.id
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func createDraft(data: Data, source: EditSourceKind) async {
        do {
            let draft = try await app.drafts.create(imageData: data, source: source, stockID: selectedStockID)
            TumbleAnalytics.shared.capture(.photoCaptured(source: source.rawValue, remainingAfter: nil))
            studioDraft = draft
        } catch {
            message = "Tumble could not create a private draft. Nothing was saved."
        }
    }

    private func firstSaveCompleted() {
        guard !analyticsPromptShown else { return }
        showAnalyticsOffer = true
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct TumbleChangedView: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's new")
                                .trackedLabel()
                                .foregroundStyle(Palette.amber)
                            Text("Tumble is now a Studio")
                                .font(Typography.heroTitle)
                                .foregroundStyle(Palette.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text("Editing now leads the way. Choose a favorite photo, find its film character, and finish it as a photograph or personal postcard.")
                                .font(Typography.body)
                                .foregroundStyle(Palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            row("photo.on.rectangle.angled", "Choose a photo from your library")
                            row("camera.filters", "Preview every film on your photo")
                            row("crop.rotate", "Crop and straighten right on the photo")
                            row("rectangle.portrait.on.rectangle.portrait", "Finish as a photo or postcard")
                            row("camera", "Take a new photo whenever you want")
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.blueDeep.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Palette.hairline))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                Button("Enter the Studio", action: onDone)
                    .buttonStyle(PrimaryButtonStyle(height: 54))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }

    private func row(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.amber)
                .frame(width: 26)
            Text(text)
                .font(Typography.headline)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
