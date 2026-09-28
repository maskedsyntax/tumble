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
            GraincoreBackground()
            GeometryReader { proxy in
                let dockHeight = studioDockHeight
                VStack(spacing: 0) {
                    topBar.frame(height: EditorChromeMetrics.topBarHeight)
                    previewSurface
                        .frame(maxHeight: .infinity)
                        .layoutPriority(1)
                        .padding(.horizontal, EditorChromeMetrics.canvasHorizontalPadding)
                        .padding(.vertical, EditorChromeMetrics.canvasVerticalPadding)
                    editorDock.frame(height: dockHeight)
                }
            }
        }
        .safeAreaPadding(.top, 2)
        .interactiveDismissDisabled()
        .task {
            sourceData = await app.drafts.sourceData(for: draft)
            await renderPreview(requestedRecipe: recipe)
            TumbleAnalytics.shared.screen(.studio)
            TumbleAnalytics.shared.capture(.studioOpened(
                source: draft.sourceKind.rawValue,
                initialFilmStockID: recipe.stockID
            ))
        }
        .onChange(of: recipe) { oldValue, value in
            app.drafts.update(value)
            schedulePreviewRender(
                value,
                debounce: oldValue.stockID == value.stockID ? .milliseconds(45) : .zero
            )
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

    private var topBar: some View {
        HStack(spacing: 7) {
            Button { showDiscard = true } label: {
                ZStack {
                    Circle()
                        .fill(Palette.cream.opacity(0.09))
                        .frame(
                            width: EditorChromeMetrics.topBarControlVisual,
                            height: EditorChromeMetrics.topBarControlVisual
                        )
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(
                    width: EditorChromeMetrics.minimumHitTarget,
                    height: EditorChromeMetrics.minimumHitTarget
                )
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Cancel editing")

            Text(recipe.stock.name)
                .font(Typography.sans(12, weight: .bold))
                .lineLimit(1)
            Spacer()
            Button { openFinish() } label: {
                ZStack {
                    Capsule().fill(Palette.gold)
                        .frame(height: EditorChromeMetrics.topBarPrimaryVisualHeight)
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 12)
                }
                .font(Typography.sans(12, weight: .bold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: true, vertical: false)
                .frame(height: EditorChromeMetrics.minimumHitTarget)
                .contentShape(Rectangle())
            }
            .disabled(preview == nil)
        }
        .foregroundStyle(Palette.cream)
        .padding(.horizontal, EditorChromeMetrics.horizontalPadding)
    }

    private var previewSurface: some View {
        ZStack {
            Color.black.opacity(0.34)
            if let image = shownImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                ProgressView().tint(Palette.gold)
            }
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text((showingOriginal || pressingOriginal) ? "ORIGINAL" : recipe.stock.name.uppercased())
                            .font(Typography.sans(9, weight: .bold))
                            .tracking(1)
                        if !showingOriginal && !pressingOriginal {
                            Text(recipe.stock.blurb)
                                .font(Typography.sans(9))
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(Palette.cream)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: 200, alignment: .leading)
                    Spacer()
                    Button {
                        showingOriginal.toggle()
                        if showingOriginal { TumbleAnalytics.shared.capture(.originalComparisonUsed) }
                    } label: {
                        Label("Compare", systemImage: "circle.lefthalf.filled")
                            .font(Typography.sans(9, weight: .bold))
                            .padding(.horizontal, 8)
                            .frame(height: 28)
                            .background(Palette.cream.opacity(0.90), in: Capsule())
                            .foregroundStyle(Palette.ink)
                            .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                            .contentShape(Rectangle())
                    }
                    .accessibilityHint("Double tap to switch between Original and Film")
                }
                .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: EditorChromeMetrics.canvasCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: EditorChromeMetrics.canvasCornerRadius, style: .continuous)
                .stroke(Palette.cream.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 12, y: 7)
        .onLongPressGesture(minimumDuration: 0.08, maximumDistance: 44, pressing: { pressed in
            if pressed, !pressingOriginal {
                TumbleAnalytics.shared.capture(.originalComparisonUsed)
            }
            pressingOriginal = pressed
        }, perform: {})
    }

    private var editorDock: some View {
        VStack(spacing: 0) {
            if adjustingAmount && selectedTool == .film {
                filmBrowserHeader
                    .padding(.horizontal, 16)
                    .frame(height: EditorChromeMetrics.filmBrowserHeaderHeight)
                amountPanel
                    .padding(.horizontal, 18)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    toolPanel
                        .padding(.horizontal, EditorChromeMetrics.dockHorizontalPadding)
                        .padding(.vertical, selectedTool == .film ? 2 : EditorChromeMetrics.dockVerticalPadding)
                }
                .frame(height: max(0, studioDockHeight - EditorChromeMetrics.toolSwitcherHeight))
                .scrollBounceBehavior(.basedOnSize)

                toolSwitcher
                    .frame(height: EditorChromeMetrics.toolSwitcherHeight)
            }
        }
        .background(Palette.blueDeep.opacity(0.98))
        .overlay(alignment: .top) { Divider().overlay(Palette.cream.opacity(0.08)) }
        .clipped()
    }

    private var toolSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(StudioTool.allCases) { tool in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selectedTool = tool }
                } label: {
                    Label(tool.title, systemImage: tool.icon)
                    .font(Typography.sans(12, weight: selectedTool == tool ? .bold : .semibold))
                    .foregroundStyle(selectedTool == tool ? Palette.gold : Palette.cream.opacity(0.68))
                    .frame(maxWidth: .infinity)
                    .frame(height: EditorChromeMetrics.minimumHitTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTool == tool ? .isSelected : [])
            }
        }
        .overlay(alignment: .top) { Divider().overlay(Palette.cream.opacity(0.08)) }
        .frame(height: EditorChromeMetrics.toolSwitcherHeight)
    }

    @ViewBuilder private var toolPanel: some View {
        switch selectedTool {
        case .film:
            filmControls
        case .crop:
            cropControls
        }
    }

    private var filmControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            filmBrowserHeader
                .padding(.horizontal, 6)
                .frame(height: EditorChromeMetrics.filmBrowserHeaderHeight)
            filmPicker
        }
        .foregroundStyle(Palette.cream)
    }

    private var filmBrowserHeader: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(FilmStockCatalog.packs) { pack in
                    Button {
                        selectPack(pack.id)
                    } label: {
                        if selectedPackID == pack.id {
                            Label(pack.name, systemImage: "checkmark")
                        } else {
                            Text(pack.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(FilmStockCatalog.packs.first(where: { $0.id == selectedPackID })?.name ?? "Films")
                        .font(Typography.display(18))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.gold)
                }
                .foregroundStyle(Palette.cream)
                .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Film collection")
            .accessibilityValue(FilmStockCatalog.packs.first(where: { $0.id == selectedPackID })?.name ?? "Films")

            Spacer(minLength: 8)

            Button {
                withAnimation(.easeOut(duration: 0.16)) { adjustingAmount.toggle() }
            } label: {
                Text(adjustingAmount ? "Done" : "Amount \(Int(recipe.intensity * 100))")
                    .font(Typography.sans(12, weight: .bold))
                    .foregroundStyle(Palette.gold)
                    .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(adjustingAmount ? "Done adjusting film amount" : "Adjust film amount")
        }
    }

    private var amountPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(recipe.stock.name)
                    .font(Typography.sans(13, weight: .bold))
                if !app.purchases.isUnlocked(recipe.stock) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.gold)
                }
                Spacer()
                Text("\(Int(recipe.intensity * 100))%")
                    .font(Typography.sans(12, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(Palette.cream)
            CompactAmountSlider(value: $recipe.intensity)
        }
    }

    private var cropControls: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                        .foregroundStyle(Palette.gold)
                        .frame(height: EditorChromeMetrics.minimumHitTarget)
                        .contentShape(Rectangle())
                }
            }
            chipRow(CropPreset.allCases, selection: recipe.cropPreset) { preset in
                recipe.cropPreset = preset
                if preset != .freeform { recipe.crop = .full }
            } label: { $0.label }

            if recipe.cropPreset == .freeform { freeformControls }
        }
        .foregroundStyle(Palette.cream)
    }

    private func openFinish() {
        app.drafts.update(recipe)
        TumbleAnalytics.shared.capture(.finishOpened(
            filmStockID: recipe.stockID,
            premium: !app.purchases.isUnlocked(recipe.stock)
        ))
        showFinish = true
    }

    private func selectPack(_ packID: String) {
        guard let firstStock = FilmStockCatalog.groupedByPack.first(where: { $0.pack.id == packID })?.stocks.first else { return }
        selectedPackID = packID
        selectFilm(firstStock)
    }

    private func selectFilm(_ stock: FilmStock) {
        recipe.stockID = stock.id
        selectedPackID = stock.packID
        lastSelectedStockID = stock.id
        showingOriginal = false
        UISelectionFeedbackGenerator().selectionChanged()
        TumbleAnalytics.shared.capture(.filmPreviewed(
            filmStockID: stock.id,
            packID: stock.packID,
            premium: !app.purchases.isUnlocked(stock)
        ))
    }

    private var filmPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(
                    FilmStockCatalog.groupedByPack.first(where: { $0.pack.id == selectedPackID })?.stocks ?? []
                ) { stock in
                    FilmThumbnailCard(
                        stock: stock,
                        sourceData: sourceData,
                        draftID: draft.id,
                        capturedAt: draft.capturedAt,
                        selected: recipe.stockID == stock.id,
                        premium: !app.purchases.isUnlocked(stock)
                    ) {
                        selectFilm(stock)
                    }
                }
            }
        }
    }

    private var freeformControls: some View {
        VStack(spacing: 6) {
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
        .padding(8)
        .background(.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
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
            HStack(spacing: 2) {
                ForEach(values) { value in
                    Button(label(value)) { action(value) }
                        .font(Typography.sans(11, weight: .semibold))
                        .foregroundStyle(selection == value ? Palette.gold : Palette.cream.opacity(0.70))
                        .frame(minWidth: 54)
                        .frame(height: EditorChromeMetrics.minimumHitTarget)
                        .overlay(alignment: .bottom) {
                            Capsule()
                                .fill(selection == value ? Palette.gold : Color.clear)
                                .frame(width: 30, height: 3)
                        }
                        .contentShape(Rectangle())
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(Typography.display(18)).foregroundStyle(Palette.cream)
    }

    private var shownImage: UIImage? { (showingOriginal || pressingOriginal) ? originalPreview : preview }

    private var compactToolNeedsRoom: Bool {
        selectedTool == .crop && recipe.cropPreset == .freeform
    }

    private var studioDockHeight: CGFloat {
        if adjustingAmount && selectedTool == .film {
            return EditorChromeMetrics.studioAmountDockHeight
        }
        if dynamicTypeSize.isAccessibilitySize {
            switch selectedTool {
            case .film:
                return EditorChromeMetrics.studioFilmAccessibilityDockHeight
            case .crop:
                return compactToolNeedsRoom
                    ? EditorChromeMetrics.studioFilmAccessibilityDockHeight
                    : EditorChromeMetrics.studioCompositionAccessibilityDockHeight
            }
        }
        switch selectedTool {
        case .film:
            return EditorChromeMetrics.studioFilmDockHeight
        case .crop:
            return compactToolNeedsRoom
                ? EditorChromeMetrics.studioFreeformDockHeight
                : EditorChromeMetrics.studioCompositionDockHeight
        }
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
        if let original = rendered.original {
            originalPreview = original
            originalPreviewRecipe = sourceRecipe
        }
    }

}

private struct CompactAmountSlider: View {
    @Binding var value: Double

    private let knobDiameter: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let travel = max(1, proxy.size.width - knobDiameter)
            let knobCenter = (knobDiameter / 2) + (travel * value)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.cream.opacity(0.16))
                    .frame(height: 3)
                Capsule()
                    .fill(Palette.gold)
                    .frame(width: knobCenter, height: 3)
                Circle()
                    .fill(Palette.cream)
                    .frame(width: knobDiameter, height: knobDiameter)
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
                    .offset(x: knobCenter - (knobDiameter / 2))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        value = min(1, max(0, (gesture.location.x - knobDiameter / 2) / travel))
                    }
            )
        }
        .frame(height: EditorChromeMetrics.minimumHitTarget)
        .accessibilityElement()
        .accessibilityLabel("Film amount")
        .accessibilityValue("\(Int(value * 100)) percent")
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
    let premium: Bool
    let action: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color.black.opacity(0.24).overlay(ProgressView().tint(Palette.gold))
                    }
                }
                .frame(
                    width: EditorChromeMetrics.filmThumbnailWidth,
                    height: EditorChromeMetrics.filmThumbnailHeight
                )
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(selected ? Palette.gold : Palette.cream.opacity(0.12), lineWidth: selected ? 2 : 1)
                }
                .overlay(alignment: .topTrailing) {
                    if premium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Palette.ink)
                            .frame(width: 20, height: 20)
                            .background(Palette.gold, in: Circle())
                            .padding(5)
                    }
                }

                Text(stock.name)
                    .font(Typography.sans(10, weight: selected ? .bold : .semibold))
                    .foregroundStyle(selected ? Palette.gold : Palette.cream.opacity(0.82))
                    .lineLimit(1)
            }
            .frame(width: EditorChromeMetrics.filmThumbnailWidth, alignment: .leading)
            .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        case .crop: return "Composition"
        }
    }

    var icon: String {
        switch self {
        case .film: return "camera.filters"
        case .crop: return "crop"
        }
    }
}
