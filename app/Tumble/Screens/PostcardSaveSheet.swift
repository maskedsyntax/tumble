import SwiftUI
import SwiftData
import TumbleKit

/// The postcard studio: pick a frame, scribble a note, choose the memory
/// filter, and save. Frames render live from the actual print, so what you
/// see is exactly what lands in Photos.
struct PostcardSaveSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The print being saved. When nil (batch save) the note editor hides and
    /// `previewPhoto` stands in for the frame previews.
    let photo: Photo?
    /// Stand-in print used to render previews when `photo` is nil.
    var previewPhoto: Photo? = nil
    /// Called when the shooter taps Save; the owning screen performs the save.
    var onSave: () -> Void = {}
    /// False while the print still needs developing.
    var saveEnabled: Bool = true

    @AppStorage(PostcardFrameStyle.storageKey) private var frameStyleRaw = PostcardFrameStyle.none.rawValue

    /// Called when a locked stock is tapped in the look picker, with its pack.
    var onLockedPack: (FilmPack) -> Void = { _ in }

    @State private var note = ""
    @State private var image: UIImage?
    /// Bumped whenever the look changes, to re-render the preview.
    @State private var lookRefresh = 0

    private var frameStyle: PostcardFrameStyle {
        if let photo { return photo.frameStyle }
        return PostcardFrameStyle(rawValue: frameStyleRaw) ?? .none
    }

    /// Frame choices are per-print; the AppStorage value is only the default
    /// for batch saves, where no single print owns the choice.
    private func selectFrame(_ style: PostcardFrameStyle) {
        if let photo {
            photo.frameStyle = style
            try? context.save()
        } else {
            frameStyleRaw = style.rawValue
        }
    }

    /// The print the previews render from.
    private var previewSource: Photo? { photo ?? previewPhoto }

    var body: some View {
        ZStack {
            GraincoreBackground()

            VStack(spacing: 0) {
                header
                    .padding(.top, 10)

                preview
                    .padding(.top, 14)

                if photo != nil {
                    noteEditor
                        .padding(.top, 14)
                }

                lookPicker
                    .padding(.top, 14)

                framePicker
                    .padding(.top, 14)

                footer
                    .padding(.top, 14)
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            note = photo?.caption ?? ""
        }
        .task(id: "\(previewSource?.id.uuidString ?? "none")|\(previewSource?.filterID ?? "")|\(lookRefresh)") {
            guard let source = previewSource else { return }
            // Preview renders the print's own stock live, so what you see is
            // exactly what lands in Photos.
            if let rawData = PhotoStore.loadImageData(named: source.rawImageName),
               let memoryData = TumblePhotoFilter.renderMemoryPhotoData(
                   from: rawData,
                   grade: source.filmStock.grade,
                   capturedAt: source.capturedAt
               ) {
                image = UIImage(data: memoryData)
            } else {
                let name = source.developedImageName ?? source.rawImageName
                image = PhotoStore.loadImageData(named: name).flatMap(UIImage.init(data:))
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Postcard")
                    .font(Typography.display(24))
                    .foregroundStyle(Palette.cream)
                Text(frameStyle.tagline)
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.6))
                    .animation(.easeOut(duration: 0.2), value: frameStyle)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .padding(9)
                    .background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    @ViewBuilder private var preview: some View {
        if let source = previewSource {
            PostcardFrameView(
                style: frameStyle,
                image: image,
                age: source.ageFraction(),
                note: note.isEmpty ? nil : note,
                capturedAt: source.capturedAt,
                seed: source.id.stableSeed,
                width: min(240 / frameStyle.aspect, 250)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 244)
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .lastTextBaseline) {
                Text("Note")
                    .font(Typography.sans(11, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.amber)
                Spacer()
                Text("\(note.count)/\(PostcardNote.maxLength)")
                    .font(Typography.sans(11, weight: .medium))
                    .foregroundStyle(note.count > PostcardNote.maxLength - 10 ? Palette.amber : Palette.cream.opacity(0.45))
                    .monospacedDigit()
            }

            TextField("Add a note…", text: $note, axis: .vertical)
                .font(Typography.script(21))
                .foregroundStyle(Palette.cream)
                .lineLimit(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Palette.charcoalDeep.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Palette.cream.opacity(0.12), lineWidth: 1)
                )
                .onChange(of: note) { _, newValue in
                    let clamped = PostcardNote.clamp(newValue)
                    if clamped != newValue { note = clamped }
                    photo?.caption = clamped.isEmpty ? nil : clamped
                    try? context.save()
                }
        }
        .accessibilityElement(children: .contain)
    }

    /// The look shelf, shown for a single print. Batch saves keep each print's
    /// own look (chosen when it developed), so there's nothing global to set.
    @ViewBuilder private var lookPicker: some View {
        if let photo {
            VStack(alignment: .leading, spacing: 8) {
                Text("Look")
                    .font(Typography.sans(11, weight: .semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LookPickerView(
                    photo: photo,
                    onChange: { lookRefresh += 1 },
                    onLocked: onLockedPack
                )
            }
        }
    }

    private var framePicker: some View {
        HStack(spacing: 7) {
            ForEach(PostcardFrameStyle.allCases) { style in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectFrame(style)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 6) {
                        thumbnail(for: style)
                            .frame(height: 68)
                        Text(style.shortName)
                            .font(Typography.sans(9.5, weight: frameStyle == style ? .bold : .medium))
                            .foregroundStyle(frameStyle == style ? Palette.gold : Palette.cream.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(width: 60)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(style.displayName) frame")
                .accessibilityAddTraits(frameStyle == style ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    /// A full, unclipped miniature of the frame - each style renders at the
    /// width that makes its natural height land in the thumbnail row.
    @ViewBuilder
    private func thumbnail(for style: PostcardFrameStyle) -> some View {
        if let source = previewSource {
            PostcardFrameView(
                style: style,
                image: image,
                age: source.ageFraction(),
                note: note.isEmpty ? nil : note,
                capturedAt: source.capturedAt,
                seed: source.id.stableSeed,
                width: 64 / style.aspect
            )
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(
                        frameStyle == style ? Palette.gold : Palette.cream.opacity(0.14),
                        lineWidth: frameStyle == style ? 2 : 1
                    )
            )
            .background(Palette.charcoalDeep.opacity(0.5))
        } else {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Palette.charcoalDeep.opacity(0.5))
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
                onSave()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                    Text(frameStyle == .none ? "Save Photo" : "Save Postcard")
                        .font(Typography.sans(14, weight: .bold))
                }
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!saveEnabled)
            .opacity(saveEnabled ? 1 : 0.45)
            .accessibilityLabel(frameStyle == .none ? "Save photo to Photos" : "Save postcard to Photos")
        }
    }
}
