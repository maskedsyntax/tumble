import SwiftUI
import TumbleAnalytics
import TumbleKit
import UIKit

struct FinishView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let draft: EditDraft
    @Binding var recipe: EditRecipe
    let onSaved: () -> Void

    @State private var format: FinishFormat
    @State private var filmPreview: UIImage?
    @State private var sourceData: Data?
    @State private var busy = false
    @State private var message: String?
    @State private var showComplete = false
    @State private var showShare = false
    @State private var shareImage: UIImage?
    @State private var pendingAction: FinishAction?
    @State private var resumeAfterUnlock = false
    @State private var showSaved = false
    @FocusState private var noteFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(draft: EditDraft, recipe: Binding<EditRecipe>, onSaved: @escaping () -> Void) {
        self.draft = draft
        _recipe = recipe
        self.onSaved = onSaved
        _format = State(initialValue: recipe.wrappedValue.frameStyle == .none ? .photo : .postcard)
#if DEBUG
        _showComplete = State(initialValue: ProcessInfo.processInfo.arguments.contains("-completeDemo"))
#endif
    }

    private var premium: Bool { !app.purchases.isUnlocked(recipe.stock) }
    private var activeFrame: PostcardFrameStyle {
        format == .photo ? .none : (recipe.frameStyle == .none ? .classicInstant : recipe.frameStyle)
    }
    private var formatName: String { format == .photo ? "photo" : "postcard" }

    var body: some View {
        ZStack {
            EditorBackground()
            VStack(spacing: 0) {
                EditorTopBar(title: "Finish") {
                    IconButton("chevron.left", accessibilityLabel: "Back to Studio") { dismiss() }
                } trailing: {
                    Color.clear.frame(width: EditorChromeMetrics.minimumHitTarget, height: 1)
                }
                preview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                    .padding(.horizontal, EditorChromeMetrics.canvasHorizontalPadding)
                    .padding(.vertical, EditorChromeMetrics.canvasVerticalPadding)
                finishDock
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
            .repairingSafeArea()
        }
        .animation(Motion.spring(reduceMotion: reduceMotion), value: format)
        .interactiveDismissDisabled(busy)
        .task {
            TumbleAnalytics.shared.screen(.finish)
            sourceData = await app.drafts.sourceData(for: draft)
            await renderFilmPreview()
        }
        .onChange(of: recipe) { _, _ in
            app.drafts.update(recipe)
            Task { await renderFilmPreview() }
        }
        .onChange(of: showComplete) { _, shown in
            guard !shown, resumeAfterUnlock, app.purchases.isUnlocked(recipe.stock), let pendingAction else { return }
            resumeAfterUnlock = false
            TumbleAnalytics.shared.capture(.exportStarted(format: formatName, action: pendingAction.rawValue, premium: true))
            Task { await perform(pendingAction) }
        }
        .overlay {
            if showSaved {
                savedConfirmation
                    .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.94)))
            }
        }
        .overlay {
            if showComplete {
                CompletePaywallView(
                    source: "premium_export",
                    onUnlocked: { resumeAfterUnlock = true },
                    onClose: { showComplete = false }
                )
                .environment(app)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showComplete)
        .animation(Motion.fade, value: showSaved)
        .sheet(isPresented: $showShare) {
            if let shareImage {
                FinishActivityView(items: [shareImage]) { completed, error in
                    if completed {
                        TumbleAnalytics.shared.capture(.exportCompleted(
                            format: formatName,
                            action: FinishAction.share.rawValue,
                            frameStyle: activeFrame.rawValue
                        ))
                        ReviewPrompter.shared.recordSuccessfulExport()
                    } else {
                        TumbleAnalytics.shared.capture(.exportFailed(
                            reason: error == nil ? "cancelled" : "share",
                            format: formatName,
                            action: FinishAction.share.rawValue
                        ))
                    }
                }
            }
        }
        .alert("Tumble", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) { Button("OK") { message = nil } } message: { Text(message ?? "") }
    }

    private var preview: some View {
        GeometryReader { proxy in
            ZStack {
                if let filmPreview {
                    if format == .photo {
                        Image(uiImage: filmPreview)
                            .resizable()
                            .scaledToFit()
                            .transition(.opacity)
                    } else {
                        let hasNote = !recipe.note.isEmpty
                        let aspect = activeFrame.renderAspect(hasNote: hasNote)
                        // Frame styles draw soft shadows outside their measured
                        // bounds. Reserve that visual overflow as well as a true
                        // 16-point clearance so no paper edge can be clipped.
                        let width = activeFrame.previewWidth(
                            inside: proxy.size,
                            hasNote: hasNote
                        )
                        PostcardFrameView(
                            style: activeFrame,
                            image: filmPreview,
                            note: hasNote ? recipe.note : nil,
                            capturedAt: draft.capturedAt,
                            seed: draft.id.stableSeed,
                            width: width
                        )
                        .frame(width: width, height: width * aspect)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(activeFrame.displayName) postcard preview")
                        .accessibilityIdentifier("Postcard style preview")
                        .transition(.opacity)
                    }
                } else {
                    ProgressView().tint(Palette.amber)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var finishDock: some View {
        VStack(spacing: 10) {
            SegmentedPill(
                options: [FinishFormat.photo, .postcard],
                selection: format,
                title: { $0.title },
                icon: { $0.icon }
            ) { choice in
                format = choice
                if choice == .postcard, recipe.frameStyle == .none {
                    recipe.frameID = PostcardFrameStyle.classicInstant.rawValue
                }
                TumbleAnalytics.shared.capture(.finishFormatSelected(format: choice.rawValue))
            }
            .padding(.horizontal, 16)

            if format == .postcard {
                VStack(spacing: 10) {
                    framePicker
                    noteField
                        .padding(.horizontal, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            actionBar
        }
        .padding(.top, 10)
        .background(Palette.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Palette.hairline).frame(height: 1) }
    }

    /// The four postcard styles, drawn as small finished postcards using the
    /// photo being edited.
    private var framePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(PostcardFrameStyle.allCases.filter { $0 != .none }) { style in
                    frameTile(style)
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Postcard style")
    }

    private func frameTile(_ style: PostcardFrameStyle) -> some View {
        let selected = activeFrame == style
        let width = EditorChromeMetrics.frameTileWidth
        let aspect = style.renderAspect(hasNote: false)
        return Button {
            guard !selected else { return }
            Haptics.selection()
            selectFrame(style)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? Palette.cream.opacity(0.10) : Palette.surfaceRaised)
                    if let filmPreview {
                        PostcardFrameView(
                            style: style,
                            image: filmPreview,
                            note: nil,
                            capturedAt: draft.capturedAt,
                            seed: draft.id.stableSeed,
                            width: width
                        )
                        .frame(width: width, height: width * aspect)
                        .allowsHitTesting(false)
                    }
                }
                .frame(width: width + 16, height: width * 1.3 + 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? Palette.amber : Palette.hairline, lineWidth: selected ? 2 : 1)
                }
                Text(style.shortName)
                    .font(selected ? Typography.captionEmphasized : Typography.caption)
                    .foregroundStyle(selected ? Palette.amber : Palette.textSecondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(style.displayName)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var noteField: some View {
        HStack(spacing: 8) {
            TextField("Add a note", text: Binding(
                get: { recipe.note },
                set: { recipe.note = PostcardNote.clamp($0) }
            ))
            .font(Typography.script(20))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(Palette.ink)
            .focused($noteFocused)
            .submitLabel(.done)
            .onSubmit { noteFocused = false }
            .accessibilityLabel("Postcard note")

            if noteFocused || !recipe.note.isEmpty {
                Text("\(recipe.note.count)/\(PostcardNote.maxLength)")
                    .font(Typography.caption.monospacedDigit())
                    .foregroundStyle(Palette.ink.opacity(0.55))
                    .accessibilityLabel("\(PostcardNote.maxLength - recipe.note.count) characters left")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: EditorChromeMetrics.minimumHitTarget)
        .background(Palette.printStock, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { noteFocused = true }
    }

    private func selectFrame(_ style: PostcardFrameStyle) {
        recipe.frameID = style.rawValue
        TumbleAnalytics.shared.capture(.postcardConfigured(
            frameStyle: style.rawValue,
            hasNote: !recipe.note.isEmpty
        ))
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button { request(.share) } label: {
                actionLabel(.share, title: "Share", icon: premium ? "lock.fill" : "square.and.arrow.up", primary: false)
            }
            .buttonStyle(SecondaryButtonStyle(height: EditorChromeMetrics.finishActionHeight))
            .frame(maxWidth: 140)
            .accessibilityLabel("Share")

            Button { request(.save) } label: {
                actionLabel(
                    .save,
                    title: premium ? "Unlock to Save" : "Save",
                    icon: premium ? "lock.fill" : "arrow.down.to.line",
                    primary: true
                )
            }
            .buttonStyle(PrimaryButtonStyle(height: EditorChromeMetrics.finishActionHeight))
            .accessibilityLabel(premium ? "Unlock to Save" : "Save")
        }
        .disabled(busy || filmPreview == nil || showSaved)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private func actionLabel(_ action: FinishAction, title: String, icon: String, primary: Bool) -> some View {
        HStack(spacing: 7) {
            if busy && pendingAction == action {
                ProgressView().tint(primary ? Palette.ink : Palette.cream)
            } else {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
            }
            Text(title)
        }
    }

    private var savedConfirmation: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Palette.amber)
            Text("Saved to Photos")
                .font(Typography.headline)
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(Palette.surfaceRaised.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func request(_ action: FinishAction) {
        pendingAction = action
        if premium {
            TumbleAnalytics.shared.capture(.premiumExportGated(filmStockID: recipe.stockID, action: action.rawValue))
            showComplete = true
            return
        }
        TumbleAnalytics.shared.capture(.exportStarted(format: formatName, action: action.rawValue, premium: false))
        Task { await perform(action) }
    }

    private func perform(_ action: FinishAction) async {
        busy = true
        defer { busy = false }
        await app.drafts.flush()
        guard let data = await exportData() else {
            TumbleAnalytics.shared.capture(.exportFailed(reason: "render", format: formatName, action: action.rawValue))
            message = "The finished image could not be rendered. Your draft is still safe."
            return
        }

        switch action {
        case .share:
            guard let image = UIImage(data: data) else {
                TumbleAnalytics.shared.capture(.exportFailed(reason: "decode", format: formatName, action: action.rawValue))
                message = "The finished image could not be prepared."
                return
            }
            shareImage = image
            showShare = true
        case .save:
            let result = await PhotoLibrarySaver.saveImageData(data)
            guard case .saved = result else {
                let reason = result == .denied ? "photos_permission" : "photos_write"
                TumbleAnalytics.shared.capture(.exportFailed(reason: reason, format: formatName, action: action.rawValue))
                message = result == .denied
                    ? "Allow Tumble to add photos in Settings, then try again. Your draft is still safe."
                    : "The finished image could not be saved. Your draft is still safe."
                return
            }
            TumbleAnalytics.shared.capture(.exportCompleted(format: formatName, action: action.rawValue, frameStyle: activeFrame.rawValue))
            if format == .postcard {
                TumbleAnalytics.shared.capture(.postcardConfigured(frameStyle: activeFrame.rawValue, hasNote: !recipe.note.isEmpty))
            }
            ReviewPrompter.shared.recordSuccessfulExport()
            Haptics.success()
            showSaved = true
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 600 : 900))
            await app.drafts.discard()
            onSaved()
        }
    }

    private func renderFilmPreview() async {
        guard let data = sourceData else { return }
        var filmRecipe = recipe
        filmRecipe.frameID = PostcardFrameStyle.none.rawValue
        filmRecipe.note = ""
        let rendered = await Task.detached(priority: .userInitiated) {
            TumblePhotoFilter.renderEditedPreview(
                from: data,
                recipe: filmRecipe,
                capturedAt: draft.capturedAt,
                maxDimension: 1200
            )
        }.value
        guard !Task.isCancelled else { return }
        filmPreview = rendered
    }

    private func exportData() async -> Data? {
        let availableSource: Data?
        if let sourceData {
            availableSource = sourceData
        } else {
            availableSource = await app.drafts.sourceData(for: draft)
        }
        guard let source = availableSource else { return nil }
        var exportRecipe = recipe
        exportRecipe.frameID = PostcardFrameStyle.none.rawValue
        exportRecipe.note = ""
        let filmData = await Task.detached(priority: .userInitiated) {
            TumblePhotoFilter.renderEditedPhotoData(
                from: source,
                recipe: exportRecipe,
                capturedAt: draft.capturedAt
            )
        }.value
        guard format == .postcard, let filmData, let image = UIImage(data: filmData) else { return filmData }

        let hasNote = !recipe.note.isEmpty
        let width = activeFrame.exportWidth(hasNote: hasNote)
        let content = PostcardFrameView(
            style: activeFrame,
            image: image,
            note: hasNote ? recipe.note : nil,
            capturedAt: draft.capturedAt,
            seed: draft.id.stableSeed,
            width: width
        )
        .frame(width: width, height: width * activeFrame.renderAspect(hasNote: hasNote))
        .background(Color.white)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        return renderer.uiImage?.jpegData(compressionQuality: 0.92)
    }
}

private enum FinishFormat: String {
    case photo
    case postcard

    var title: String { rawValue.capitalized }
    var icon: String { self == .photo ? "photo" : "rectangle.portrait.on.rectangle.portrait" }
}

private enum FinishAction: String, Equatable {
    case save
    case share
}

private struct FinishActivityView: UIViewControllerRepresentable {
    let items: [Any]
    let completion: (Bool, Error?) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, error in
            completion(completed, error)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
