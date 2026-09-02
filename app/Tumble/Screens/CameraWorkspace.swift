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
    @State private var studioDraft: EditDraft?
    @State private var showSettings = false
    @State private var showComplete = false
    @State private var showResume = false
    @State private var showAnalyticsOffer = false
    @State private var captureInProgress = false
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
        }
        .task {
            await app.startStore()
            permission = AVCaptureDevice.authorizationStatus(for: .video)
            if permission == .authorized { startCamera() }
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-studioDemo"),
               let data = FilmScene.goldenHour.image(size: 1400).jpegData(compressionQuality: 0.96),
               let draft = try? app.drafts.create(imageData: data, source: .camera, stockID: selectedStockID) {
                studioDraft = draft
                return
            }
#endif
            if app.drafts.activeDraft != nil { showResume = true }
        }
        .onChange(of: selectedStockID) { _, _ in updatePreviewFilm() }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
        .onDisappear { camera.stop() }
        .fullScreenCover(item: $studioDraft) { draft in
            StudioView(draft: draft) { firstSaveCompleted() }.environment(app)
        }
        .sheet(isPresented: $showSettings) { TumbleSettingsView().environment(app) }
        .sheet(isPresented: $showComplete) { CompletePaywallView().environment(app) }
        .confirmationDialog("Continue your last edit?", isPresented: $showResume, titleVisibility: .visible) {
            Button("Continue editing") { studioDraft = app.drafts.activeDraft }
            Button("Discard draft", role: .destructive) { app.drafts.discard() }
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
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.28), in: Circle())
            }
        }
    }

    private var viewfinder: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.black)
                if permission == .authorized {
                    CameraPreview(session: camera.session)
                    if let filtered = camera.filteredPreview {
                        Image(uiImage: filtered)
                            .resizable().scaledToFill()
                            .scaleEffect(x: camera.side == .front ? -1 : 1, y: 1)
                    }
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
        .frame(maxHeight: .infinity)
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(FilmStockCatalog.all) { stock in
                    let unlocked = app.purchases.isUnlocked(stock)
                    Button {
                        guard unlocked else { showComplete = true; return }
                        selectedStockID = stock.id
                    } label: {
                        HStack(spacing: 5) {
                            Text(stock.name)
                            if !unlocked { Image(systemName: "lock.fill").font(.caption2) }
                        }
                        .font(Typography.sans(12, weight: .semibold))
                        .foregroundStyle(selectedStockID == stock.id ? Palette.ink : Palette.cream)
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(selectedStockID == stock.id ? Palette.gold : .black.opacity(0.24), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
            captureInProgress = false
            switch result {
            case .success(let image):
                guard let data = image.jpegData(compressionQuality: 0.98) else {
                    message = "The captured image could not be prepared. No draft was created."
                    return
                }
                createDraft(data: data, source: .camera)
            case .unavailable(let reason): message = reason
            case .failure(let reason, _): message = reason
            }
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        defer { selectedItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                message = "That image could not be imported."
                return
            }
            createDraft(data: data, source: .library)
        } catch {
            message = "That image could not be imported."
        }
    }

    private func createDraft(data: Data, source: EditSourceKind) {
        do {
            let draft = try app.drafts.create(imageData: data, source: source, stockID: selectedStockID)
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
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "camera.filters")
                    .font(.system(size: 64, weight: .light)).foregroundStyle(Palette.gold)
                Text("Tumble has changed")
                    .font(Typography.display(35)).foregroundStyle(Palette.cream)
                Text("The daily roll and development ritual have made room for a faster private film camera and Studio. Your old prints are safe in Settings → Legacy Drawer.")
                    .font(Typography.sans(15)).foregroundStyle(Palette.cream.opacity(0.72))
                    .multilineTextAlignment(.center).padding(.horizontal, 34)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Shoot or import any photo", systemImage: "camera")
                    Label("Preview and adjust every film", systemImage: "camera.filters")
                    Label("Nothing enters Photos until you save", systemImage: "lock.shield")
                }
                .font(Typography.sans(14, weight: .semibold)).foregroundStyle(Palette.cream)
                Spacer()
                Button(action: onDone) {
                    Text("Meet Tumble 3")
                        .font(Typography.sans(16, weight: .bold)).foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Palette.gold, in: Capsule())
                }
                .padding(.horizontal, 28).padding(.bottom, 24)
            }
        }
    }
}
