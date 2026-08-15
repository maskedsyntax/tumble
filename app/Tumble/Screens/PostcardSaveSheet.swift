import SwiftUI
import SwiftData
import TumbleKit

/// The postcard studio: pick a frame, scribble a note, choose the memory
/// filter, and save. Frames render live from the actual print, so what you
/// see is exactly what lands in Photos.
struct PostcardSaveSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app

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

    @State private var note = ""
    @State private var image: UIImage?
    @FocusState private var noteFocused: Bool
    /// The pack to sell, set by tapping a locked look. Presented from here
    /// rather than from whoever presented this sheet: a view can only show one
    /// sheet at a time, so a paywall anchored on the parent never appeared.
    @State private var lockedPack: FilmPack?
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

            // Header and Save stay put; everything between them scrolls. As a
            // plain VStack this screen was ~750pt of content in ~810pt of
            // sheet, so raising the keyboard squashed the note field to a
            // sliver and pushed the frame thumbnails over their own labels.
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                ScrollView {
                    VStack(spacing: 0) {
                        preview
                            .padding(.top, 12)

                        // The look comes first: it is the choice that changes
                        // the photo, and the reason to open this screen at all.
                        lookPicker
                            .padding(.top, 18)

                        if photo != nil {
                            noteEditor
                                .padding(.top, 18)
                        }

                        framePicker
                            .padding(.top, 18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)

                footer
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
            }
        }
        .sheet(item: $lockedPack) { pack in
            PackPaywallView(pack: pack)
                .environment(app)
                .presentationDetents([.medium, .large])
        }
        .toolbar {
            // Without this the keyboard has no way out: the note is a
            // multi-line field, so Return inserts a newline rather than
            // dismissing.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { noteFocused = false }
                    .font(Typography.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.gold)
            }
        }
        .onAppear {
            note = photo?.caption ?? ""
            if DebugLaunch.focusesNote { noteFocused = true }
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
                .focused($noteFocused)
                .lineLimit(2...4)
                .frame(minHeight: 46, alignment: .topLeading)
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
                    onLocked: { lockedPack = $0 }
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
                        // A fixed box per column. The thumbnail is sized from
                        // the frame's own aspect so the tallest style still
                        // lands inside it and never covers the label below.
                        thumbnail(for: style)
                            .frame(width: 60, height: 62)
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
                width: 58 / style.aspect
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
