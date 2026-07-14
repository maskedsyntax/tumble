import SwiftUI
import SwiftData
import TumbleKit

/// A developed print pulled out of the Drawer, full-screen. Riffle left/right
/// through the rest of the developed pile; swipe down to toss it back in.
struct PrintDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let developed: [Photo]
    @State private var index: Int
    @State private var dragY: CGFloat = 0
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var confirmRemove = false
    @AppStorage("tumble.saveIncludesPostcardFrame") private var saveIncludesPostcardFrame = false
    @AppStorage(TumbleMemoryFilterPreset.storageKey) private var memoryFilterPresetRaw = TumbleMemoryFilterPreset.defaultPreset.rawValue

    init(developed: [Photo], start: Photo) {
        self.developed = developed
        _index = State(initialValue: developed.firstIndex(where: { $0.id == start.id }) ?? 0)
    }

    var body: some View {
        ZStack {
            GraincoreBackground()

            TabView(selection: $index) {
                ForEach(Array(developed.enumerated()), id: \.element.id) { i, photo in
                    DetailPrint(photo: photo)
                        .tag(i)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            metadata
            saveStatus
            topControls
        }
        .offset(y: dragY)
        .gesture(
            // Toss back into the drawer with a downward flick.
            DragGesture()
                .onChanged { v in dragY = max(0, v.translation.height) }
                .onEnded { v in
                    if v.translation.height > 120 { dismiss() }
                    else { withAnimation(.spring) { dragY = 0 } }
                }
        )
    }

    private var current: Photo? {
        developed.indices.contains(index) ? developed[index] : nil
    }

    private var memoryFilterPreset: TumbleMemoryFilterPreset {
        TumbleMemoryFilterPreset(rawValue: memoryFilterPresetRaw) ?? .defaultPreset
    }

    @ViewBuilder private var metadata: some View {
        if let current {
            VStack {
                Spacer()
                Text(current.capturedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.55))
                    .padding(.bottom, 28)
            }
        }
    }

    @ViewBuilder private var saveStatus: some View {
        if let saveMessage {
            VStack {
                Spacer()
                Text(saveMessage)
                    .font(Typography.sans(13, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.78))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.28), in: Capsule())
                    .padding(.bottom, 58)
            }
            .transition(.opacity)
        }
    }

    private var topControls: some View {
        VStack {
            HStack(spacing: 10) {
                Spacer()
                Button { confirmRemove = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                        .frame(width: 35, height: 35)
                        .background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(current == nil)
                .accessibilityLabel("Remove print")

                saveOptionsMenu

                Button { Task { await saveCurrent() } } label: {
                    ZStack {
                        if isSaving {
                            ProgressView()
                                .tint(Palette.cream)
                                .controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Palette.cream)
                    .frame(width: 35, height: 35)
                    .background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isSaving || current == nil)
                .accessibilityLabel("Save print to Photos")

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                        .padding(10).background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 6)
        .confirmationDialog(
            "Remove this print from your Drawer?",
            isPresented: $confirmRemove,
            titleVisibility: .visible
        ) {
            Button("Remove print", role: .destructive) { removeCurrent() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will not return the shot.")
        }
    }

    private var saveOptionsMenu: some View {
        Menu {
            Picker("Memory filter", selection: $memoryFilterPresetRaw) {
                ForEach(TumbleMemoryFilterPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset.rawValue)
                }
            }

            Divider()

            Toggle(isOn: $saveIncludesPostcardFrame) {
                Label("Save as postcard", systemImage: "photo.artframe")
            }
        } label: {
            Image(systemName: saveIncludesPostcardFrame ? "photo.artframe" : "photo")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(saveIncludesPostcardFrame ? Palette.gold : Palette.cream)
                .frame(width: 35, height: 35)
                .background(.black.opacity(0.28), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save format options")
    }

    @MainActor
    private func saveCurrent() async {
        guard let current, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let style: PhotoLibrarySaveStyle = saveIncludesPostcardFrame ? .postcardFrame : .photoOnly
        let result = await PhotoLibrarySaver.saveDeveloped(current, style: style)
        withAnimation(.easeOut(duration: 0.2)) {
            saveMessage = message(for: result, style: style)
        }
        if case .saved = result {
            ReviewPrompter.shared.recordSavedToPhotos()
        }
    }

    private func message(for result: PhotoLibrarySaveResult, style: PhotoLibrarySaveStyle) -> String {
        switch result {
        case .saved:
            return style == .postcardFrame ? "Saved postcard to Photos." : "Saved \(memoryFilterPreset.exportLabel) photo to Photos."
        case .noDevelopedPhotos:
            return "Develop this print before saving."
        case .denied:
            return "Allow Photos access to save prints."
        case .failed:
            return "Could not save. Try again."
        }
    }

    private func removeCurrent() {
        guard let current else { return }
        PhotoStore.deleteImages(for: current)
        context.delete(current)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

/// One full-screen print that loads its bytes and shows age-accurate grade.
private struct DetailPrint: View {
    let photo: Photo
    @State private var image: UIImage?

    var body: some View {
        PrintView(
            image: image,
            isDeveloped: true,
            developProgress: 1,
            age: photo.ageFraction(),
            caption: photo.caption,
            width: 320
        )
        .rotationEffect(.degrees(photo.rotation * 0.25))
        .task(id: photo.id) {
            let name = photo.developedImageName ?? photo.rawImageName
            image = PhotoStore.loadImageData(named: name).flatMap(UIImage.init(data:))
        }
    }
}
