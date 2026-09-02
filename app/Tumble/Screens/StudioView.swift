import SwiftUI
import TumbleAnalytics
import TumbleKit
import UIKit

struct StudioView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    let draft: EditDraft
    let onSaved: () -> Void

    @State private var recipe: EditRecipe
    @State private var preview: UIImage?
    @State private var originalPreview: UIImage?
    @State private var showingOriginal = false
    @State private var showDiscard = false
    @State private var showComplete = false
    @State private var showShare = false
    @State private var shareImage: UIImage?
    @State private var busy = false
    @State private var message: String?

    init(draft: EditDraft, onSaved: @escaping () -> Void) {
        self.draft = draft
        self.onSaved = onSaved
        _recipe = State(initialValue: draft.recipe)
    }

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        previewSurface
                        filmControls
                        finishingControls
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }
        }
        .safeAreaPadding(.top, 4)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .interactiveDismissDisabled()
        .task { await renderPreview() }
        .onChange(of: recipe) { _, value in
            app.drafts.update(value)
            Task { await renderPreview() }
        }
        .onAppear { TumbleAnalytics.shared.pauseReplay() }
        .onDisappear { TumbleAnalytics.shared.resumeReplay() }
        .confirmationDialog("Discard this edit?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("Discard draft", role: .destructive) {
                app.drafts.discard()
                dismiss()
            }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("The original and your edits have not been saved to Photos.")
        }
        .sheet(isPresented: $showComplete) { CompletePaywallView().environment(app) }
        .sheet(isPresented: $showShare) {
            if let shareImage { ActivityView(items: [shareImage]) }
        }
        .alert("Tumble", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) { Button("OK") { message = nil } } message: { Text(message ?? "") }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { showDiscard = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 42, height: 42)
                    .background(Palette.cream.opacity(0.10), in: Circle())
            }
            .accessibilityLabel("Cancel editing")

            Spacer()
            VStack(spacing: 1) {
                Text("Studio")
                    .font(Typography.display(25))
                Text(recipe.stock.name)
                    .font(Typography.sans(10, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                    .lineLimit(1)
            }
            Spacer()
            Color.clear.frame(width: 42, height: 42)
        }
        .foregroundStyle(Palette.cream)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var previewSurface: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ZStack {
                    Color.black.opacity(0.28)
                    if let image = shownImage {
                        if recipe.frameStyle == .none || showingOriginal {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .padding(8)
                        } else {
                            PostcardFrameView(
                                style: recipe.frameStyle,
                                image: image,
                                note: recipe.note.isEmpty ? nil : recipe.note,
                                capturedAt: draft.capturedAt,
                                seed: draft.id.stableSeed,
                                width: max(1, proxy.size.width - 20)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        ProgressView().tint(Palette.gold)
                    }
                }
            }
            .aspectRatio(previewAspect, contentMode: .fit)
            .frame(maxHeight: 430)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(showingOriginal ? "SOURCE" : "FILM PREVIEW")
                        .font(Typography.sans(9, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Palette.cream.opacity(0.48))
                    Text(showingOriginal ? "Original" : recipe.stock.name)
                        .font(Typography.sans(13, weight: .bold))
                        .foregroundStyle(Palette.cream)
                }
                Spacer()
                Picker("Preview", selection: $showingOriginal) {
                    Text("Original").tag(true)
                    Text("Film").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 164)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Palette.charcoalDeep.opacity(0.78))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.cream.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }

    private var filmControls: some View {
        editorCard {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("Film")
                Spacer()
                Text("\(FilmStockCatalog.all.count) looks")
                    .font(Typography.sans(10, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.42))
            }
            filmPicker
            Divider().overlay(Palette.cream.opacity(0.08))
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Intensity").font(Typography.sans(13, weight: .semibold))
                    Text("Blend the film with your original")
                        .font(Typography.sans(9))
                        .foregroundStyle(Palette.cream.opacity(0.45))
                }
                Slider(value: $recipe.intensity, in: 0...1)
                    .tint(Palette.gold)
                Text("\(Int(recipe.intensity * 100))")
                    .font(Typography.sans(11, weight: .bold))
                    .monospacedDigit()
                    .frame(width: 28)
                    .padding(.vertical, 6)
                    .background(Palette.cream.opacity(0.08), in: Capsule())
            }
        }
    }

    private var finishingControls: some View {
        editorCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    sectionTitle("Crop")
                    Text("Choose the final composition")
                        .font(Typography.sans(9))
                        .foregroundStyle(Palette.cream.opacity(0.45))
                }
                Spacer()
                Button { recipe.quarterTurns = (recipe.quarterTurns + 1) % 4 } label: {
                    Label("Rotate", systemImage: "rotate.right")
                        .font(Typography.sans(11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Palette.cream.opacity(0.09), in: Capsule())
                }
            }
            chipRow(CropPreset.allCases, selection: recipe.cropPreset) { preset in
                recipe.cropPreset = preset
                if preset != .freeform { recipe.crop = .full }
            } label: { $0.label }

            if recipe.cropPreset == .freeform { freeformControls }

            Divider().overlay(Palette.cream.opacity(0.08)).padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 2) {
                sectionTitle("Postcard")
                Text("Optional frame and handwritten note")
                    .font(Typography.sans(9))
                    .foregroundStyle(Palette.cream.opacity(0.45))
            }
            chipRow(PostcardFrameStyle.allCases, selection: recipe.frameStyle) { style in
                recipe.frameID = style.rawValue
            } label: { $0.shortName }

            if recipe.frameStyle != .none {
                TextField("Write something small…", text: Binding(
                    get: { recipe.note },
                    set: { recipe.note = PostcardNote.clamp($0) }
                ))
                .font(Typography.script(20))
                .foregroundStyle(Palette.ink)
                .padding(13)
                .background(Palette.printStock, in: RoundedRectangle(cornerRadius: 13))
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button { prepareShare() } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Palette.cream.opacity(0.10), in: RoundedRectangle(cornerRadius: 17))
                    .overlay(RoundedRectangle(cornerRadius: 17).stroke(Palette.cream.opacity(0.12)))
            }
            Button { Task { await save() } } label: {
                HStack(spacing: 8) {
                    if busy { ProgressView().tint(Palette.ink) }
                    else { Image(systemName: "arrow.down.to.line.compact") }
                    Text("Save photo")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 17))
                .foregroundStyle(Palette.ink)
            }
        }
        .font(Typography.sans(14, weight: .bold))
        .foregroundStyle(Palette.cream)
        .padding(.horizontal, 16)
        .padding(.top, 11)
        .padding(.bottom, 8)
        .background(Palette.blueDeep.opacity(0.97))
        .overlay(alignment: .top) { Divider().overlay(Palette.cream.opacity(0.08)) }
        .disabled(busy || preview == nil)
    }

    private var filmPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FilmStockCatalog.all) { stock in
                    let unlocked = app.purchases.isUnlocked(stock)
                    Button {
                        guard unlocked else { showComplete = true; return }
                        recipe.stockID = stock.id
                        TumbleAnalytics.shared.capture(.filmStockSelected(filmStockID: stock.id, packID: stock.packID))
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 5) {
                                Text(stock.name).font(Typography.sans(12, weight: .bold)).lineLimit(1)
                                if !unlocked { Image(systemName: "lock.fill").font(.caption2) }
                            }
                            Text(stock.blurb)
                                .font(Typography.sans(9))
                                .lineLimit(2)
                                .foregroundStyle(Palette.cream.opacity(0.52))
                        }
                        .frame(width: 136, height: 48, alignment: .topLeading)
                        .padding(12)
                        .background(recipe.stockID == stock.id ? Palette.gold.opacity(0.22) : .black.opacity(0.18), in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(recipe.stockID == stock.id ? Palette.gold : Palette.cream.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var freeformControls: some View {
        VStack(spacing: 8) {
            cropSlider("Width", value: $recipe.crop.width)
            cropSlider("Height", value: $recipe.crop.height)
            cropSlider("Horizontal", value: Binding(
                get: { recipe.crop.x },
                set: { recipe.crop.x = min(1 - recipe.crop.width, $0) }
            ), upper: max(0.001, 1 - recipe.crop.width))
            cropSlider("Vertical", value: Binding(
                get: { recipe.crop.y },
                set: { recipe.crop.y = min(1 - recipe.crop.height, $0) }
            ), upper: max(0.001, 1 - recipe.crop.height))
        }
        .padding(12)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
    }

    private func cropSlider(_ name: String, value: Binding<Double>, upper: Double = 1) -> some View {
        HStack {
            Text(name).font(Typography.sans(10, weight: .semibold)).frame(width: 68, alignment: .leading)
            Slider(value: value, in: (name == "Width" || name == "Height" ? 0.2 : 0)...upper)
                .tint(Palette.gold)
        }
    }

    private func chipRow<T: Identifiable & Equatable>(
        _ values: [T], selection: T, action: @escaping (T) -> Void, label: @escaping (T) -> String
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values) { value in
                    Button(label(value)) { action(value) }
                        .font(Typography.sans(11, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(selection == value ? Palette.gold : Palette.cream.opacity(0.09), in: Capsule())
                        .foregroundStyle(selection == value ? Palette.ink : Palette.cream)
                }
            }
        }
    }

    private func editorCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .foregroundStyle(Palette.cream)
            .padding(16)
            .background(Palette.blueDeep.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.cream.opacity(0.06)))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(Typography.display(20)).foregroundStyle(Palette.cream)
    }

    private var shownImage: UIImage? { showingOriginal ? originalPreview : preview }

    private var previewAspect: CGFloat {
        if recipe.frameStyle != .none, !showingOriginal {
            return max(0.72, min(1.7, 1 / recipe.frameStyle.aspect))
        }
        guard let size = shownImage?.size, size.height > 0 else { return 4.0 / 3.0 }
        return max(0.72, min(1.7, size.width / size.height))
    }

    private func renderPreview() async {
        guard let data = app.drafts.sourceData(for: draft) else {
            preview = nil
            originalPreview = nil
            return
        }
        let requestedRecipe = recipe
        let capturedAt = draft.capturedAt
        let rendered = await Task.detached(priority: .userInitiated) {
            var sourceRecipe = requestedRecipe
            sourceRecipe.intensity = 0
            sourceRecipe.frameID = PostcardFrameStyle.none.rawValue
            sourceRecipe.note = ""
            return (
                TumblePhotoFilter.renderEditedPreview(from: data, recipe: requestedRecipe, capturedAt: capturedAt),
                TumblePhotoFilter.renderEditedPreview(from: data, recipe: sourceRecipe, capturedAt: capturedAt)
            )
        }.value
        guard requestedRecipe == recipe else { return }
        preview = rendered.0
        originalPreview = rendered.1
    }

    private func exportData() async -> Data? {
        guard let source = app.drafts.sourceData(for: draft) else { return nil }
        let requestedRecipe = recipe
        let capturedAt = draft.capturedAt
        guard let filmData = await Task.detached(priority: .userInitiated, operation: {
            TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: requestedRecipe, capturedAt: capturedAt)
        }).value else { return nil }
        guard requestedRecipe.frameStyle != .none, let image = UIImage(data: filmData) else { return filmData }
        let width = floor(4096 / max(1, requestedRecipe.frameStyle.aspect))
        let content = PostcardFrameView(
            style: requestedRecipe.frameStyle,
            image: image,
            note: requestedRecipe.note.isEmpty ? nil : requestedRecipe.note,
            capturedAt: capturedAt,
            seed: draft.id.stableSeed,
            width: width
        )
        .background(Color.white)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        return renderer.uiImage?.jpegData(compressionQuality: 0.92)
    }

    private func prepareShare() {
        Task {
            busy = true
            defer { busy = false }
            guard let data = await exportData(), let image = UIImage(data: data) else {
                message = "The edited image could not be prepared. Your draft is still safe."
                return
            }
            shareImage = image
            showShare = true
        }
    }

    private func save() async {
        busy = true
        defer { busy = false }
        guard let data = await exportData() else {
            message = "The edited image could not be rendered. Your draft is still safe."
            return
        }
        let result = await PhotoLibrarySaver.saveImageData(data)
        switch result {
        case .saved:
            TumbleAnalytics.shared.capture(.photoSaved(format: "jpeg", frameStyle: recipe.frameID, photoCount: 1))
            app.drafts.discard()
            onSaved()
            dismiss()
        case .denied:
            message = "Allow Tumble to add photos in Settings, then try again. Your draft is still safe."
        default:
            TumbleAnalytics.shared.capture(.photoSaveFailed(reason: "photos_write", format: "jpeg", photoCount: 1))
            message = "The photo could not be saved. Your draft is still safe."
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
