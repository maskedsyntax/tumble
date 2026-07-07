import SwiftUI
import TumbleKit

/// A single local-day collection. It keeps the print feeling, but uses lazy
/// loading so heavy days and long archives stay reachable.
struct DayCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    let day: PhotoDay

    @State private var selected: Photo?
    @State private var isSaving = false
    @State private var saveMessage: String?
    @AppStorage("tumble.saveIncludesPostcardFrame") private var saveIncludesPostcardFrame = false

    private var developed: [Photo] {
        day.photos.filter(\.isDeveloped)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 138, maximum: 176), spacing: 18, alignment: .top)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            GraincoreBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let saveMessage {
                        Text(saveMessage)
                            .font(Typography.sans(13, weight: .semibold))
                            .foregroundStyle(Palette.cream.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 2)
                    }

                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(day.photos) { photo in
                            Button { selected = photo } label: {
                                DayCollectionPrint(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 44)
            }

            closeButton
        }
        .fullScreenCover(item: $selected) { photo in
            PrintStage(photo: photo, developed: developed)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.displayTitle)
                        .font(Typography.display(32))
                        .foregroundStyle(Palette.cream)
                    Text("\(day.developedCount) developed · \(day.totalCount) total")
                        .font(Typography.sans(13))
                        .foregroundStyle(Palette.cream.opacity(0.58))
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    saveOptionsMenu

                    Button { Task { await saveDay() } } label: {
                        HStack(spacing: 7) {
                            if isSaving {
                                ProgressView()
                                    .tint(Palette.ink)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(isSaving ? "Saving" : "Save day")
                                .font(Typography.sans(13, weight: .bold))
                        }
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(Palette.gold, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving || developed.isEmpty)
                    .opacity(developed.isEmpty ? 0.45 : 1)
                    .accessibilityLabel("Save developed prints from this day")
                }
            }
        }
    }

    private var saveOptionsMenu: some View {
        Menu {
            Toggle(isOn: $saveIncludesPostcardFrame) {
                Label("Save as postcard", systemImage: "photo.artframe")
            }
        } label: {
            Image(systemName: saveIncludesPostcardFrame ? "photo.artframe" : "photo")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(saveIncludesPostcardFrame ? Palette.ink : Palette.cream)
                .frame(width: 34, height: 34)
                .background(saveIncludesPostcardFrame ? Palette.gold : .black.opacity(0.28), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save format options")
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .padding(10)
                    .background(.black.opacity(0.3), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close collection")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @MainActor
    private func saveDay() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let style: PhotoLibrarySaveStyle = saveIncludesPostcardFrame ? .postcardFrame : .photoOnly
        let result = await PhotoLibrarySaver.saveDeveloped(in: day.photos, style: style)
        withAnimation(.easeOut(duration: 0.2)) {
            saveMessage = message(for: result, style: style)
        }
    }

    private func message(for result: PhotoLibrarySaveResult, style: PhotoLibrarySaveStyle) -> String {
        switch result {
        case .saved(let count):
            let noun = style == .postcardFrame ? "postcard" : "photo"
            return count == 1 ? "Saved 1 \(noun) to Photos." : "Saved \(count) \(noun)s to Photos."
        case .noDevelopedPhotos:
            return "Develop prints before saving them."
        case .denied:
            return "Allow Photos access to save prints."
        case .failed:
            return "Could not save. Try again."
        }
    }
}

private struct DayCollectionPrint: View {
    let photo: Photo
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            PrintView(
                image: image,
                isDeveloped: photo.isDeveloped,
                developProgress: photo.isDeveloped ? 1 : photo.developProgress,
                age: photo.ageFraction(),
                caption: photo.caption,
                width: 138
            )
            Text(photo.capturedAt.formatted(date: .omitted, time: .shortened))
                .font(Typography.sans(11, weight: .medium))
                .foregroundStyle(Palette.cream.opacity(0.5))
        }
        .task(id: photo.id) {
            let name = photo.developedImageName ?? photo.rawImageName
            image = PhotoStore.loadImageData(named: name).flatMap(UIImage.init(data:))
        }
        .accessibilityElement()
        .accessibilityLabel(
            photo.isDeveloped
                ? "Developed print from \(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))"
                : "Undeveloped shot from \(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))"
        )
        .accessibilityAddTraits(.isButton)
    }
}
