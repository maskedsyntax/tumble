import SwiftData
import SwiftUI
import TumbleAnalytics
import TumbleKit
import UIKit

/// Everything you've finished: Studio edits land here when they are saved or
/// shared, beside any prints kept from the retired roll.
struct DrawerLibraryView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]
    @State private var selectedEdit: Photo?
    @State private var selectedPrint: Photo?
    /// Reopens a finished print in Studio. Home presents it once the Drawer
    /// is out of the way.
    var onEditAgain: (EditDraft) -> Void = { _ in }

    private var edits: [Photo] { photos.filter(\.isStudioEdit) }
    private var legacyPrints: [Photo] { photos.filter { !$0.isStudioEdit } }

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drawer")
                            .font(Typography.largeTitle)
                            .foregroundStyle(Palette.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        // The trailing no-break space keeps the script's last
                        // stroke from being clipped at the line's edge.
                        Text("every photo & postcard you've finished\u{00A0}")
                            .font(Typography.script(22))
                            .foregroundStyle(Palette.creamDim.opacity(0.8))
                    }
                    Spacer()
                    IconButton("xmark", accessibilityLabel: "Close Drawer") { dismiss() }
                }
                .padding(.horizontal, 20)

                if photos.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(months, id: \.start) { month in
                                monthSection(month)
                            }
                            if !legacyPrints.isEmpty { legacySection }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(.top, 10)
        }
        .onAppear { TumbleAnalytics.shared.screen(.drawer) }
        .fullScreenCover(item: $selectedEdit) { photo in
            FinishedPrintView(edits: edits, start: photo) { draft in
                selectedEdit = nil
                onEditAgain(draft)
            }
            .environment(app)
            .repairingSafeArea()
        }
        .fullScreenCover(item: $selectedPrint) {
            PrintStage(photo: $0, developed: legacyPrints.filter(\.isDeveloped)).environment(app)
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 18, alignment: .top)]
    }

    /// Finished prints grouped by the month they were finished, newest first,
    /// like pages of an album.
    private var months: [(start: Date, prints: [Photo])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: edits) {
            calendar.dateInterval(of: .month, for: $0.capturedAt)?.start ?? $0.capturedAt
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    private func monthSection(_ month: (start: Date, prints: [Photo])) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(month.start.formatted(.dateTime.month(.wide).year()))
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(month.prints.count == 1 ? "1 print" : "\(month.prints.count) prints")
                    .trackedLabel()
                    .foregroundStyle(Palette.amber)
            }
            LazyVGrid(columns: columns, spacing: 26) {
                ForEach(month.prints) { photo in
                    DrawerEditTile(photo: photo) { selectedEdit = photo }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Palette.amber)
            Text("Nothing in your Drawer yet")
                .font(Typography.title)
                .foregroundStyle(Palette.textPrimary)
            Text("Photos and postcards you save or share are kept here, so you can share them again or keep editing.")
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var legacySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("From the roll")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Prints from earlier versions of Tumble")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 18) {
                ForEach(legacyPrints) { photo in
                    DrawerPrintTile(photo: photo) {
                        selectedPrint = photo
                        if !photo.isDeveloped { Task { await finish(photo) } }
                    }
                }
            }
        }
    }

    private func finish(_ photo: Photo) async {
        guard let raw = await PhotoStore.loadImageDataAsync(named: photo.rawImageName) else { return }
        let grade = photo.filmStock.grade
        let capturedAt = photo.capturedAt
        guard let rendered = await Task.detached(priority: .userInitiated, operation: {
            TumblePhotoFilter.renderMemoryPhotoData(from: raw, grade: grade, capturedAt: capturedAt)
        }).value else { return }
        photo.developedImageName = try? await PhotoStore.writeImageAsync(rendered, id: photo.id, kind: .developed)
        photo.developProgress = 1
        photo.isDeveloped = true
        try? context.save()
    }
}

/// A finished edit as a keepsake in the drawer. A photo is mounted on print
/// stock with its film and date written along the bottom margin; a postcard
/// is already a card, so it sits as it was exported with the note beneath.
/// Each one rests at its own slight angle, as if tossed in.
private struct DrawerEditTile: View {
    let photo: Photo
    let action: () -> Void
    @State private var image: UIImage?

    private var isPostcard: Bool { photo.frameStyle != .none }

    var body: some View {
        Button(action: action) {
            Group {
                if isPostcard { postcard } else { mountedPhoto }
            }
            .rotationEffect(.degrees(photo.rotation * 0.22))
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(photo.filmStock.name) \(isPostcard ? "postcard" : "photo"), \(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityAddTraits(.isButton)
        .task(id: "\(photo.developedImageName ?? "")|\(photo.capturedAt.timeIntervalSince1970)") {
            image = await PhotoThumbnailRepository.shared.image(named: photo.developedImageName, maxPixelSize: 520)
        }
    }

    private var mountedPhoto: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .overlay {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Palette.creamDim
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.black.opacity(0.15), lineWidth: 0.5))
            HStack(alignment: .firstTextBaseline) {
                Text(photo.filmStock.name.lowercased())
                Spacer(minLength: 4)
                Text(photo.capturedAt.formatted(.dateTime.day().month(.abbreviated)).lowercased())
            }
            .font(Typography.scriptFixed(19))
            .foregroundStyle(Palette.ink.opacity(0.74))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.top, 7)
            .padding(.horizontal, 2)
        }
        .padding(9)
        .padding(.bottom, 1)
        .background(Palette.printStock)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.42), radius: 7, x: 0, y: 5)
    }

    private var postcard: some View {
        VStack(spacing: 10) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    Palette.printStock.aspectRatio(4.0 / 5.0, contentMode: .fit)
                }
            }
            .shadow(color: .black.opacity(0.42), radius: 7, x: 0, y: 5)
            Text("\(photo.frameStyle.displayName.lowercased()) · \(photo.capturedAt.formatted(.dateTime.day().month(.abbreviated)).lowercased())")
                .font(Typography.scriptFixed(19))
                .foregroundStyle(Palette.creamDim.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct DrawerPrintTile: View {
    let photo: Photo
    let action: () -> Void
    @State private var image: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PrintView(image: image, isDeveloped: photo.isDeveloped, width: 132)
                    .rotationEffect(.degrees(photo.rotation * 0.22))
                Text(photo.isDeveloped ? photo.filmStock.name.lowercased() : "tap to finish developing")
                    .font(Typography.scriptFixed(19))
                    .foregroundStyle(photo.isDeveloped ? Palette.creamDim.opacity(0.78) : Palette.gold)
            }
        }
        .buttonStyle(.plain)
        .task(id: photo.developedImageName) {
            let name = photo.developedImageName ?? photo.rawImageName
            image = await PhotoThumbnailRepository.shared.image(named: name, maxPixelSize: 420)
        }
    }
}

/// A finished edit, full-screen. Swipe through the rest, save or share it
/// again, or reopen it in Studio.
struct FinishedPrintView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let edits: [Photo]
    let onEditAgain: (EditDraft) -> Void
    @State private var index: Int
    @State private var busy = false
    @State private var status: String?
    @State private var message: String?
    @State private var confirmRemove = false
    @State private var shareItem: ShareItem?

    init(edits: [Photo], start: Photo, onEditAgain: @escaping (EditDraft) -> Void) {
        self.edits = edits
        self.onEditAgain = onEditAgain
        _index = State(initialValue: edits.firstIndex(where: { $0.id == start.id }) ?? 0)
    }

    private var current: Photo? {
        edits.indices.contains(index) ? edits[index] : nil
    }

    var body: some View {
        ZStack {
            // A browsing surface like Home and the roll prints, not an editor.
            GraincoreBackground()
            VStack(spacing: 0) {
                EditorTopBar(title: current.map { $0.filmStock.name }) {
                    IconButton("xmark", accessibilityLabel: "Back to Drawer") { dismiss() }
                } trailing: {
                    IconButton("trash", accessibilityLabel: "Remove from Drawer") { confirmRemove = true }
                        .disabled(current == nil)
                }

                TabView(selection: $index) {
                    ForEach(Array(edits.enumerated()), id: \.element.id) { i, photo in
                        FinishedImage(photo: photo)
                            .padding(.horizontal, EditorChromeMetrics.canvasHorizontalPadding)
                            .padding(.vertical, EditorChromeMetrics.canvasVerticalPadding)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .overlay(alignment: .bottom) { statusPill }

                actions
            }
        }
        .onAppear { TumbleAnalytics.shared.screen(.printDetail) }
        .onChange(of: index) { _, _ in status = nil }
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.image])
        }
        .confirmationDialog("Remove this from your Drawer?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) { removeCurrent() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Copies already saved to Photos stay there.")
        }
        .alert("Tumble", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) { Button("OK") { message = nil } } message: { Text(message ?? "") }
    }

    @ViewBuilder private var statusPill: some View {
        if let status {
            Text(status)
                .font(Typography.captionEmphasized)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Palette.surfaceRaised.opacity(0.94), in: Capsule())
                .padding(.bottom, 14)
                .transition(.opacity)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if let current {
                Text(caption(for: current))
                    .font(Typography.script(22))
                    .foregroundStyle(Palette.creamDim.opacity(0.8))
            }
            Button { Task { await editAgain() } } label: {
                Label("Edit Again", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(PrimaryButtonStyle())
            HStack(spacing: 10) {
                Button { Task { await share() } } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle(height: 46))
                Button { Task { await save() } } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(SecondaryButtonStyle(height: 46))
            }
        }
        .disabled(busy || current == nil)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func caption(for photo: Photo) -> String {
        let kind = photo.frameStyle == .none ? "photo" : photo.frameStyle.displayName.lowercased()
        return "\(kind) · finished \(photo.capturedAt.formatted(.dateTime.day().month(.wide).year()))"
    }

    private func finishedData() async -> Data? {
        await PhotoStore.loadImageDataAsync(named: current?.developedImageName)
    }

    private func share() async {
        guard let data = await finishedData(), let image = UIImage(data: data) else {
            message = "This print could not be opened."
            return
        }
        shareItem = ShareItem(image: image)
    }

    private func save() async {
        guard let current else { return }
        busy = true
        defer { busy = false }
        guard let data = await finishedData() else {
            message = "This print could not be opened."
            return
        }
        let format = current.frameStyle == .none ? "photo" : "postcard"
        let result = await PhotoLibrarySaver.saveImageData(data)
        switch result {
        case .saved:
            TumbleAnalytics.shared.capture(.photoSaved(format: format, frameStyle: current.frameStyle.rawValue, photoCount: 1))
            ReviewPrompter.shared.recordSavedToPhotos()
            Haptics.success()
            withAnimation(.easeOut(duration: 0.2)) { status = "Saved to Photos" }
        case .denied:
            TumbleAnalytics.shared.capture(.photoSaveFailed(reason: "permission_denied", format: format, photoCount: 1))
            message = "Allow Tumble to add photos in Settings, then try again."
        case .failed, .noDevelopedPhotos:
            TumbleAnalytics.shared.capture(.photoSaveFailed(reason: "library_error", format: format, photoCount: 1))
            message = "This print could not be saved. Try again."
        }
    }

    private func editAgain() async {
        guard let current, let edit = current.edit else { return }
        busy = true
        defer { busy = false }
        guard let source = await PhotoStore.loadImageDataAsync(named: current.rawImageName),
              let draft = try? await app.drafts.create(
                imageData: source,
                source: edit.sourceKind,
                recipe: edit.recipe,
                capturedAt: edit.capturedAt
              ) else {
            message = "The original photo for this print is missing, so it can't be edited again."
            return
        }
        onEditAgain(draft)
    }

    private func removeCurrent() {
        guard let current else { return }
        PhotoStore.deleteImages(for: current)
        context.delete(current)
        try? context.save()
        TumbleAnalytics.shared.capture(.photoRemoved(state: "finished"))
        if edits.count <= 1 { dismiss() }
    }
}

/// The exported photo or postcard, fitted to the canvas.
private struct FinishedImage: View {
    let photo: Photo
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
            } else {
                ProgressView().tint(Palette.amber)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement()
        .accessibilityLabel("Finished \(photo.filmStock.name) \(photo.frameStyle == .none ? "photo" : "postcard")")
        .accessibilityAddTraits(.isImage)
        .task(id: photo.developedImageName) {
            image = await PhotoThumbnailRepository.shared.image(named: photo.developedImageName, maxPixelSize: 2048)
        }
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
