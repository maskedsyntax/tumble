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
    @FocusState private var noteFocused: Bool

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
            GraincoreBackground()
            GeometryReader { proxy in
                // Finish is a preview-first screen. Keep format and postcard
                // configuration compact so the finished image stays dominant,
                // especially on 4.7-inch phones and with larger text sizes.
                let dockHeight = finishDockHeight
                VStack(spacing: 0) {
                    header.frame(height: EditorChromeMetrics.topBarHeight)
                    preview
                        .frame(maxHeight: .infinity)
                        .layoutPriority(1)
                        .padding(.horizontal, EditorChromeMetrics.canvasHorizontalPadding)
                        .padding(.vertical, EditorChromeMetrics.canvasVerticalPadding)
                    finishDock.frame(height: dockHeight)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
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

    private var header: some View {
        HStack(spacing: 6) {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(Palette.cream.opacity(0.09))
                        .frame(
                            width: EditorChromeMetrics.topBarControlVisual,
                            height: EditorChromeMetrics.topBarControlVisual
                        )
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.cream)
                }
                .frame(
                    width: EditorChromeMetrics.minimumHitTarget,
                    height: EditorChromeMetrics.minimumHitTarget
                )
                .contentShape(Rectangle())
            }
            Text("Finish").font(Typography.display(20)).foregroundStyle(Palette.cream)
            Spacer()
            Label(recipe.stock.name, systemImage: "camera.filters")
                .font(Typography.sans(9, weight: .bold))
                .foregroundStyle(Palette.gold)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Palette.cream.opacity(0.08), in: Capsule())
                .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                .lineLimit(1)
        }
        .padding(.horizontal, EditorChromeMetrics.horizontalPadding)
    }

    private var preview: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.32)
                if let filmPreview {
                    if format == .photo {
                        Image(uiImage: filmPreview)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
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
                    }
                } else {
                    ProgressView().tint(Palette.gold)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: EditorChromeMetrics.canvasCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: EditorChromeMetrics.canvasCornerRadius)
                .stroke(Palette.cream.opacity(0.08))
        )
    }

    private var finishDock: some View {
        VStack(spacing: 0) {
            formatPicker
                .padding(.horizontal, EditorChromeMetrics.horizontalPadding)
            if format == .postcard {
                postcardControls
                    .padding(.horizontal, EditorChromeMetrics.horizontalPadding)
                    .padding(.bottom, 6)
            }
        }
        .background(Palette.blueDeep.opacity(0.98))
        .overlay(alignment: .top) { Divider().overlay(Palette.cream.opacity(0.08)) }
    }

    private var formatPicker: some View {
        HStack(spacing: 0) {
            formatButton(.photo)
            formatButton(.postcard)
        }
        .frame(height: EditorChromeMetrics.finishFormatRowHeight)
    }

    private func formatButton(_ choice: FinishFormat) -> some View {
        Button {
            format = choice
            if choice == .postcard, recipe.frameStyle == .none {
                recipe.frameID = PostcardFrameStyle.classicInstant.rawValue
            }
            TumbleAnalytics.shared.capture(.finishFormatSelected(format: choice.rawValue))
        } label: {
            Text(choice.title)
                .font(Typography.sans(13, weight: .bold))
                .foregroundStyle(format == choice ? Palette.gold : Palette.cream.opacity(0.64))
            .frame(maxWidth: .infinity)
            .frame(height: EditorChromeMetrics.minimumHitTarget)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(format == choice ? Palette.gold : Color.clear)
                    .frame(width: 56, height: 3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(format == choice ? .isSelected : [])
    }

    private var postcardControls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 4) {
                    styleMenu
                    noteField
                }
            } else {
                HStack(spacing: 8) {
                    styleMenu
                    noteField
                }
            }
        }
    }

    private var styleMenu: some View {
        Menu {
            ForEach(PostcardFrameStyle.allCases.filter { $0 != .none }) { style in
                Button {
                    selectFrame(style)
                } label: {
                    if activeFrame == style {
                        Label(style.displayName, systemImage: "checkmark")
                    } else {
                        Text(style.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(activeFrame.shortName)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(Typography.sans(11, weight: .bold))
            .foregroundStyle(Palette.cream)
            .padding(.horizontal, 12)
            .frame(height: EditorChromeMetrics.minimumHitTarget)
            .background(Palette.cream.opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
            .frame(
                maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Postcard style")
        .accessibilityValue(activeFrame.displayName)
    }

    private var noteField: some View {
        TextField("Write something small…", text: Binding(
            get: { recipe.note },
            set: { recipe.note = PostcardNote.clamp($0) }
        ))
        .font(Typography.script(18))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .foregroundStyle(Palette.ink)
        .focused($noteFocused)
        .submitLabel(.done)
        .onSubmit { noteFocused = false }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: EditorChromeMetrics.minimumHitTarget)
        .background(Palette.printStock, in: RoundedRectangle(cornerRadius: 11))
        .contentShape(Rectangle())
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
            actionButton(
                .share,
                title: "Share",
                icon: "square.and.arrow.up",
                primary: false
            )
            Spacer(minLength: 0)
            actionButton(
                .save,
                title: premium ? "Unlock to Save" : "Save",
                icon: premium ? "lock.fill" : "arrow.down.to.line.compact",
                primary: true
            )
        }
        .padding(.horizontal, EditorChromeMetrics.horizontalPadding)
        .padding(.vertical, 4)
        .background(Palette.blueDeep.opacity(0.98))
        .overlay(alignment: .top) { Divider().overlay(Palette.cream.opacity(0.08)) }
    }

    private func actionButton(_ action: FinishAction, title: String, icon: String, primary: Bool) -> some View {
        Button {
            request(action)
        } label: {
            HStack(spacing: 7) {
                if busy && pendingAction == action { ProgressView().tint(primary ? Palette.ink : Palette.cream) }
                else { Image(systemName: icon) }
                Text(title)
            }
            .font(Typography.sans(13, weight: .bold))
            .foregroundStyle(primary ? Palette.ink : Palette.cream)
            .frame(maxWidth: .infinity)
            .frame(height: EditorChromeMetrics.finishActionVisualHeight)
            .background(
                primary ? Palette.gold : Palette.cream.opacity(0.08),
                in: RoundedRectangle(cornerRadius: EditorChromeMetrics.finishActionCornerRadius)
            )
            .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .disabled(busy || filmPreview == nil)
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

    private var finishDockHeight: CGFloat {
        if dynamicTypeSize.isAccessibilitySize, format == .postcard {
            return EditorChromeMetrics.finishAccessibilityDockHeight
        }
        return format == .postcard
            ? EditorChromeMetrics.finishPostcardDockHeight
            : EditorChromeMetrics.finishPhotoDockHeight
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
