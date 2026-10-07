import SwiftUI
import TumbleAnalytics
import TumbleKit
import UIKit

struct StudioView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let draft: EditDraft
    let onSaved: () -> Void

    @State private var recipe: EditRecipe
    @State private var preview: UIImage?
    @State private var originalPreview: UIImage?
    @State private var showingOriginal = false
    @State private var pressingOriginal = false
    @State private var showDiscard = false
    @State private var showFinish = false
    @State private var selectedTool: StudioTool = .film
    @State private var adjustingAmount = false
    @State private var previewRenderTask: Task<Void, Never>?
    @State private var originalPreviewRecipe: EditRecipe?
    @State private var sourceData: Data?
    @State private var previewWorker = StudioPreviewWorker()
    @State private var selectedPackID: String
    @State private var amountBeforeAdjusting: Double = 1
    @State private var previewStockID: String?
    @State private var previewIsStale = false
    @State private var cropBase: UIImage?
    @State private var cropBaseRecipe: EditRecipe?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(FilmStockCatalog.storageKey) private var lastSelectedStockID = FilmStockCatalog.defaultStock.id

    init(draft: EditDraft, onSaved: @escaping () -> Void) {
        self.draft = draft
        self.onSaved = onSaved
        _recipe = State(initialValue: draft.recipe)
        _selectedPackID = State(initialValue: draft.recipe.stock.packID)
        _showingOriginal = State(initialValue: DebugLaunch.showsOriginal)
        _selectedTool = State(initialValue:
            StudioTool(rawValue: DebugLaunch.value(for: "-studioTool") ?? "") ?? .film
        )
#if DEBUG
        _adjustingAmount = State(initialValue: ProcessInfo.processInfo.arguments.contains("-amountDemo"))
        _showFinish = State(initialValue: ProcessInfo.processInfo.arguments.contains("-finishDemo"))
#endif
    }

    var body: some View {
        ZStack {
            EditorBackground()
            VStack(spacing: 0) {
                topBar
                canvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                editorDock
                    .frame(height: dockHeight)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
        .interactiveDismissDisabled()
        .task {
            sourceData = await app.drafts.sourceData(for: draft)
            await renderPreview(requestedRecipe: recipe)
            if selectedTool == .crop { await renderCropBase() }
            TumbleAnalytics.shared.screen(.studio)
            TumbleAnalytics.shared.capture(.studioOpened(
                source: draft.sourceKind.rawValue,
                initialFilmStockID: recipe.stockID
            ))
        }
        .onChange(of: recipe) { oldValue, value in
            app.drafts.update(value)
            let geometryOnly = oldValue.stockID == value.stockID
                && oldValue.intensity == value.intensity
                && oldValue.quarterTurns == value.quarterTurns
            if selectedTool == .crop, geometryOnly {
                // The crop canvas draws geometry live; refresh the finished
                // preview once, when the crop tool is left.
                previewIsStale = true
                return
            }
            schedulePreviewRender(
                value,
                debounce: oldValue.stockID == value.stockID ? .milliseconds(45) : .zero
            )
            if selectedTool == .crop { Task { await renderCropBase() } }
        }
        .onChange(of: selectedTool) { _, tool in
            adjustingAmount = false
            if tool == .crop {
                Task { await renderCropBase() }
            } else if previewIsStale {
                previewIsStale = false
                schedulePreviewRender(recipe, debounce: .zero)
            }
        }
        .onAppear { TumbleAnalytics.shared.pauseReplay() }
        .onDisappear {
            previewRenderTask?.cancel()
            Task { await app.drafts.flush() }
            TumbleAnalytics.shared.resumeReplay()
        }
        .confirmationDialog("Discard this edit?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("Discard draft", role: .destructive) {
                Task {
                    await app.drafts.discard()
                    dismiss()
                }
            }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("The original and your edits have not been saved to Photos.")
        }
        .fullScreenCover(isPresented: $showFinish) {
            FinishView(draft: draft, recipe: $recipe) {
                onSaved()
                dismiss()
            }
            .environment(app)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        EditorTopBar(title: selectedTool == .crop ? "Crop" : nil) {
            IconButton("xmark", accessibilityLabel: "Cancel editing") { showDiscard = true }
        } trailing: {
            if selectedTool == .film { compareButton }
            Button { openFinish() } label: {
                HStack(spacing: 5) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .buttonStyle(PrimaryButtonStyle(fill: false, height: EditorChromeMetrics.topBarPrimaryVisualHeight))
            .accessibilityLabel("Next")
            .disabled(preview == nil)
        }
    }

    private var compareButton: some View {
        Button {
            showingOriginal.toggle()
            Haptics.selection()
            if showingOriginal { TumbleAnalytics.shared.capture(.originalComparisonUsed) }
        } label: {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(showingOriginal ? Palette.ink : Palette.textPrimary)
                .frame(width: EditorChromeMetrics.iconButtonVisual, height: EditorChromeMetrics.iconButtonVisual)
                .background(showingOriginal ? Palette.cream : Palette.surfaceRaised, in: Circle())
                .overlay(Circle().stroke(Palette.hairline))
                .frame(width: EditorChromeMetrics.minimumHitTarget, height: EditorChromeMetrics.minimumHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Compare")
        .accessibilityValue(showingOriginal ? "Showing original" : "Showing film")
        .accessibilityHint("Double tap to switch between Original and Film. Touch and hold the photo to peek.")
    }

    // MARK: Canvas

    @ViewBuilder private var canvas: some View {
        switch selectedTool {
        case .crop:
            CropCanvas(base: cropBase, recipe: $recipe)
                .padding(.horizontal, EditorChromeMetrics.canvasHorizontalPadding)
                .padding(.vertical, EditorChromeMetrics.canvasVerticalPadding)
                .transition(.opacity)
        case .film:
            resultCanvas
                .transition(.opacity)
        }
    }

    private var resultCanvas: some View {
        ZStack {
            if let image = shownImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .id(showsOriginal ? "original" : (previewStockID ?? recipe.stockID))
                    .transition(.opacity)
                    .accessibilityLabel(showsOriginal ? "Original photo" : "Photo with \(recipe.stock.name)")
            } else {
                ProgressView().tint(Palette.amber)
            }
        }
        .animation(Motion.fade, value: previewStockID)
        .animation(Motion.fade, value: showsOriginal)
        .padding(.horizontal, EditorChromeMetrics.canvasHorizontalPadding)
        .padding(.vertical, EditorChromeMetrics.canvasVerticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.08, maximumDistance: 44, pressing: { pressed in
            if pressed, !pressingOriginal {
                TumbleAnalytics.shared.capture(.originalComparisonUsed)
            }
            pressingOriginal = pressed
        }, perform: {})
        .overlay(alignment: .topLeading) {
            if showsOriginal {
                Text("Original")
                    .trackedLabel()
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(EditorChromeMetrics.overlayInset)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: Dock

    private var editorDock: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTool {
                case .film:
                    if adjustingAmount {
                        amountPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        filmBrowser
                            .transition(.opacity)
                    }
                case .crop:
                    cropControls
                        .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)

            SegmentedPill(
                options: StudioTool.allCases,
                selection: selectedTool,
                title: { $0.title },
                icon: { $0.icon }
            ) { selectedTool = $0 }
            .padding(.horizontal, 16)
            .frame(height: EditorChromeMetrics.toolSwitcherHeight)
        }
        .padding(.bottom, 2)
        .background(Palette.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Palette.hairline).frame(height: 1) }
        .animation(Motion.spring(reduceMotion: reduceMotion), value: adjustingAmount)
        .animation(Motion.fade, value: selectedTool)
    }

    private var filmBrowser: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(FilmStockCatalog.packs) { pack in
                            Chip(title: pack.name, selected: selectedPackID == pack.id) {
                                Haptics.selection()
                                withAnimation(Motion.fade) { selectedPackID = pack.id }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Film collection")

                IconButton("slider.horizontal.3", accessibilityLabel: "Adjust film amount") { beginAdjustingAmount() }
                    .padding(.trailing, 8)
            }
            filmPicker
        }
        .padding(.top, 6)
        .foregroundStyle(Palette.textPrimary)
    }

    private var filmPicker: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(
                        FilmStockCatalog.groupedByPack.first(where: { $0.pack.id == selectedPackID })?.stocks ?? []
                    ) { stock in
                        FilmThumbnailCard(
                            stock: stock,
                            sourceData: sourceData,
                            draftID: draft.id,
                            capturedAt: draft.capturedAt,
                            selected: recipe.stockID == stock.id,
                            amount: recipe.intensity,
                            premium: !app.purchases.isUnlocked(stock)
                        ) {
                            if recipe.stockID == stock.id {
                                beginAdjustingAmount()
                            } else {
                                selectFilm(stock)
                            }
                        }
                        .id(stock.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear { reader.scrollTo(recipe.stockID, anchor: .center) }
            .onChange(of: selectedPackID) { _, _ in
                reader.scrollTo(recipe.stockID, anchor: .center)
            }
        }
    }

    private var amountPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                IconButton("xmark", accessibilityLabel: "Cancel film amount") {
                    recipe.intensity = amountBeforeAdjusting
                    adjustingAmount = false
                }
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    HStack(spacing: 5) {
                        Text(recipe.stock.name)
                            .font(Typography.headline)
                        if !app.purchases.isUnlocked(recipe.stock) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Palette.amber)
                                .accessibilityLabel("Tumble Complete")
                        }
                    }
                    Text(recipe.stock.blurb)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
                .foregroundStyle(Palette.textPrimary)
                Spacer(minLength: 0)
                IconButton("checkmark", accessibilityLabel: "Done adjusting film amount") {
                    adjustingAmount = false
                }
            }
            .padding(.horizontal, 8)

            HStack(spacing: 14) {
                CompactAmountSlider(value: $recipe.intensity)
                Text("\(Int((recipe.intensity * 100).rounded()))")
                    .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Palette.textPrimary)
                    .frame(width: 48, alignment: .trailing)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxHeight: .infinity)
    }

    private var cropControls: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                IconButton("rotate.right", accessibilityLabel: "Rotate") { rotateQuarterTurn() }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(CropPreset.allCases) { preset in
                            Chip(title: preset.label, selected: recipe.cropPreset == preset) {
                                selectCropPreset(preset)
                            }
                            .accessibilityLabel(preset.accessibilityName)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                IconButton("arrow.counterclockwise", accessibilityLabel: "Reset crop") { resetGeometry() }
            }
            .padding(.horizontal, 8)

            StraightenRuler(degrees: $recipe.straighten)
                .padding(.horizontal, 16)
        }
        .padding(.top, 6)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Actions

    private func openFinish() {
        app.drafts.update(recipe)
        TumbleAnalytics.shared.capture(.finishOpened(
            filmStockID: recipe.stockID,
            premium: !app.purchases.isUnlocked(recipe.stock)
        ))
        showFinish = true
    }

    private func beginAdjustingAmount() {
        amountBeforeAdjusting = recipe.intensity
        Haptics.selection()
        adjustingAmount = true
    }

    private func selectFilm(_ stock: FilmStock) {
        recipe.stockID = stock.id
        selectedPackID = stock.packID
        lastSelectedStockID = stock.id
        showingOriginal = false
        Haptics.selection()
        TumbleAnalytics.shared.capture(.filmPreviewed(
            filmStockID: stock.id,
            packID: stock.packID,
            premium: !app.purchases.isUnlocked(stock)
        ))
    }

    private var cropBaseAspect: Double {
        guard let cropBase, cropBase.size.height > 0 else { return 1 }
        return cropBase.size.width / cropBase.size.height
    }

    private func selectCropPreset(_ preset: CropPreset) {
        guard preset != recipe.cropPreset else { return }
        Haptics.selection()
        let current = CropGeometry.effectiveCrop(for: recipe, imageAspect: cropBaseAspect)
        withAnimation(Motion.spring(reduceMotion: reduceMotion)) {
            recipe.cropPreset = preset
            // Free keeps whatever is framed now; a locked shape starts as the
            // largest centered crop of that shape.
            recipe.crop = preset == .freeform ? current : .full
        }
    }

    private func rotateQuarterTurn() {
        Haptics.selection()
        recipe.quarterTurns = (recipe.quarterTurns + 1) % 4
        // The image changes shape, so any drawn crop no longer applies.
        recipe.crop = .full
    }

    private func resetGeometry() {
        Haptics.soft()
        withAnimation(Motion.spring(reduceMotion: reduceMotion)) {
            recipe.cropPreset = .original
            recipe.crop = .full
            recipe.quarterTurns = 0
            recipe.straighten = 0
        }
    }

    // MARK: Derived

    private var showsOriginal: Bool { showingOriginal || pressingOriginal }

    private var shownImage: UIImage? { showsOriginal ? originalPreview : preview }

    private var dockHeight: CGFloat {
        if dynamicTypeSize.isAccessibilitySize { return EditorChromeMetrics.studioDockAccessibilityHeight }
        if dynamicTypeSize >= .xLarge { return EditorChromeMetrics.studioDockLargeTextHeight }
        return EditorChromeMetrics.studioDockHeight
    }

    private func schedulePreviewRender(_ requestedRecipe: EditRecipe, debounce: Duration) {
        previewRenderTask?.cancel()
        previewRenderTask = Task { @MainActor in
            if debounce != .zero {
                try? await Task.sleep(for: debounce)
            }
            guard !Task.isCancelled else { return }
            await renderPreview(requestedRecipe: requestedRecipe)
        }
    }

    private func renderPreview(requestedRecipe: EditRecipe) async {
        guard let data = sourceData else {
            preview = nil
            originalPreview = nil
            return
        }
        let capturedAt = draft.capturedAt
        var sourceRecipe = requestedRecipe
        sourceRecipe.stockID = FilmStockCatalog.defaultStock.id
        sourceRecipe.intensity = 0
        sourceRecipe.frameID = PostcardFrameStyle.none.rawValue
        sourceRecipe.note = ""
        let needsOriginal = originalPreviewRecipe != sourceRecipe
        guard let rendered = await previewWorker.render(
            data: data,
            recipe: requestedRecipe,
            sourceRecipe: sourceRecipe,
            capturedAt: capturedAt,
            needsOriginal: needsOriginal
        ) else { return }
        guard !Task.isCancelled, requestedRecipe == recipe else { return }
        preview = rendered.preview
        previewStockID = requestedRecipe.stockID
        if let original = rendered.original {
            originalPreview = original
            originalPreviewRecipe = sourceRecipe
        }
    }


    /// The film-rendered photo after quarter turns, before straightening and
    /// cropping: what the crop canvas draws its geometry over.
    private func renderCropBase() async {
        guard let data = sourceData else { return }
        var baseRecipe = recipe
        baseRecipe.straighten = 0
        baseRecipe.cropPreset = .original
        baseRecipe.crop = .full
        baseRecipe.frameID = PostcardFrameStyle.none.rawValue
        baseRecipe.note = ""
        guard baseRecipe != cropBaseRecipe else { return }
        let capturedAt = draft.capturedAt
        guard let image = await previewWorker.renderBase(data: data, recipe: baseRecipe, capturedAt: capturedAt) else { return }
        cropBase = image
        cropBaseRecipe = baseRecipe
    }
}

private struct CompactAmountSlider: View {
    @Binding var value: Double

    private let knobDiameter: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let travel = max(1, proxy.size.width - knobDiameter)
            let knobCenter = (knobDiameter / 2) + (travel * value)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.cream.opacity(0.16))
                    .frame(height: 4)
                Capsule()
                    .fill(Palette.amber)
                    .frame(width: knobCenter, height: 4)
                Circle()
                    .fill(Palette.cream)
                    .frame(width: knobDiameter, height: knobDiameter)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    .offset(x: knobCenter - (knobDiameter / 2))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let next = min(1, max(0, (gesture.location.x - knobDiameter / 2) / travel))
                        if (value < 1 && next >= 1) || (value > 0 && next <= 0) { Haptics.soft() }
                        value = next
                    }
            )
        }
        .frame(height: EditorChromeMetrics.minimumHitTarget)
        .accessibilityElement()
        .accessibilityLabel("Film amount")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(1, value + 0.05)
            case .decrement: value = max(0, value - 0.05)
            @unknown default: break
            }
        }
    }
}

private struct FilmThumbnailCard: View {
    let stock: FilmStock
    let sourceData: Data?
    let draftID: UUID
    let capturedAt: Date
    let selected: Bool
    let amount: Double
    let premium: Bool
    let action: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Palette.surfaceRaised.overlay(ProgressView().tint(Palette.amber))
                    }
                }
                .frame(
                    width: EditorChromeMetrics.filmThumbnailWidth,
                    height: EditorChromeMetrics.filmThumbnailHeight
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    if premium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Palette.textPrimary)
                            .frame(width: 20, height: 20)
                            .background(.black.opacity(0.6), in: Circle())
                            .padding(5)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if selected {
                        HStack(spacing: 3) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(Int((amount * 100).rounded()))")
                                .font(.system(size: 11, weight: .bold).monospacedDigit())
                        }
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(Palette.amber, in: Capsule())
                        .padding(5)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? Palette.amber : Palette.hairline, lineWidth: selected ? 2 : 1)
                }

                Text(stock.name)
                    .font(selected ? Typography.captionEmphasized : Typography.caption)
                    .foregroundStyle(selected ? Palette.amber : Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: EditorChromeMetrics.filmThumbnailWidth + 8, alignment: .top)
            }
            .frame(width: EditorChromeMetrics.filmThumbnailWidth + 8)
            .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .task(id: "\(draftID.uuidString)|\(stock.id)|\(sourceData == nil ? 0 : 1)") {
            guard let sourceData else { return }
            let key = "\(draftID.uuidString)|\(stock.id)"
            if let data = await FilmThumbnailRepository.shared.thumbnail(
                key: key,
                sourceData: sourceData,
                stock: stock,
                capturedAt: capturedAt
            ) {
                image = UIImage(data: data)
            }
        }
        .accessibilityLabel("\(stock.name). \(stock.blurb)\(premium ? ". Tumble Complete" : "")")
        .accessibilityHint(selected ? "Double tap to adjust the amount" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private actor FilmThumbnailRepository {
    static let shared = FilmThumbnailRepository()
    private var values: [String: Data] = [:]
    private var order: [String] = []
    private let limit = 32

    func thumbnail(
        key: String,
        sourceData: Data,
        stock: FilmStock,
        capturedAt: Date
    ) -> Data? {
        if let cached = values[key] { return cached }
        guard !Task.isCancelled else { return nil }
        let recipe = EditRecipe(stockID: stock.id)
        guard let image = TumblePhotoFilter.renderEditedPreview(
            from: sourceData,
            recipe: recipe,
            capturedAt: capturedAt,
            maxDimension: 320
        ), !Task.isCancelled,
              let data = image.jpegData(compressionQuality: 0.76) else { return nil }
        values[key] = data
        order.append(key)
        while order.count > limit {
            values.removeValue(forKey: order.removeFirst())
        }
        return data
    }
}

private struct StudioPreviewResult: @unchecked Sendable {
    let preview: UIImage?
    let original: UIImage?
}

/// Serializes Core Image work so rapid filter taps cannot leave several
/// detached GPU renders fighting each other. Cancelled queued requests exit
/// before decoding or rendering; the newest request runs next.
private actor StudioPreviewWorker {
    func renderBase(data: Data, recipe: EditRecipe, capturedAt: Date) -> UIImage? {
        guard !Task.isCancelled else { return nil }
        return TumblePhotoFilter.renderEditedPreview(
            from: data,
            recipe: recipe,
            capturedAt: capturedAt,
            maxDimension: 1200
        )
    }

    func render(
        data: Data,
        recipe: EditRecipe,
        sourceRecipe: EditRecipe,
        capturedAt: Date,
        needsOriginal: Bool
    ) -> StudioPreviewResult? {
        guard !Task.isCancelled else { return nil }
        let preview = TumblePhotoFilter.renderEditedPreview(
            from: data,
            recipe: recipe,
            capturedAt: capturedAt
        )
        guard !Task.isCancelled else { return nil }
        let original = needsOriginal
            ? TumblePhotoFilter.renderEditedPreview(
                from: data,
                recipe: sourceRecipe,
                capturedAt: capturedAt
            )
            : nil
        guard !Task.isCancelled else { return nil }
        return StudioPreviewResult(preview: preview, original: original)
    }
}

private enum StudioTool: String, CaseIterable, Identifiable {
    case film
    case crop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .film: return "Film"
        case .crop: return "Crop"
        }
    }

    var icon: String {
        switch self {
        case .film: return "camera.filters"
        case .crop: return "crop.rotate"
        }
    }
}
