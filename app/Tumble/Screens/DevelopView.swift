import SwiftUI
import SwiftData
import TumbleKit

/// The develop table. A blank, face-down print you bring to life by shaking -
/// washed out at first, settling into full color like real instant film.
///
/// On arrival the print plays a short, one-time gesture demo (a smooth ~2s
/// rock) to show what to do, then rests. Real developing is driven by shake
/// (Core Motion); under Reduce Motion or on the Simulator a press-and-hold
/// stands in.
struct DevelopView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let photo: Photo

    @State private var shake = ShakeMonitor()
    @State private var image: UIImage?
    @State private var progress: Double = 0
    @State private var holding = false
    @State private var demo = 0            // bumped once to play the gesture demo
    @State private var confirmRemove = false
    @State private var isSaving = false
    @State private var saveMessage: String?
    @AppStorage("tumble.saveIncludesPostcardFrame") private var saveIncludesPostcardFrame = false

    private var usesShake: Bool { shake.isAvailable && !reduceMotion }
    private var developed: Bool { progress >= 1 }

    var body: some View {
        ZStack {
            GraincoreBackground()

            VStack(spacing: 28) {
                Spacer()
                printCard
                hint
                Spacer()
            }
            .padding(24)

            saveStatus
            topControls
        }
        .task(id: photo.id) { await setup() }
        .onDisappear { shake.stop() }
    }

    // MARK: Print + gesture demo

    private var printCard: some View {
        PrintView(
            image: image,
            isDeveloped: developed,
            developProgress: progress,
            age: 0,
            width: 280
        )
        // One-time, self-terminating "rock" that demonstrates the shake, then
        // rests at zero. No looping, no jitter.
        .keyframeAnimator(initialValue: DemoMotion(), trigger: demo) { view, m in
            view.rotationEffect(.degrees(m.angle)).offset(x: m.angle * 1.4)
        } keyframes: { _ in
            KeyframeTrack(\.angle) {
                CubicKeyframe(0, duration: 0.15)
                CubicKeyframe(-5, duration: 0.4)
                CubicKeyframe(5, duration: 0.45)
                CubicKeyframe(-4, duration: 0.45)
                CubicKeyframe(0, duration: 0.45)
            }
        }
        .scaleEffect(developed ? 1 : 0.985)
        .animation(.easeOut(duration: 0.4), value: developed)
    }

    // MARK: Hint / fallback control

    @ViewBuilder private var hint: some View {
        if developed {
            Text("There it is.")
                .font(Typography.display(22)).foregroundStyle(Palette.cream)
                .transition(.opacity)
        } else if usesShake {
            VStack(spacing: 8) {
                Text("Shake to develop")
                    .font(Typography.display(22)).foregroundStyle(Palette.cream)
                Text("Give it a shake and watch it come up.")
                    .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.7))
            }
            .multilineTextAlignment(.center)
        } else {
            VStack(spacing: 12) {
                Text("Hold to develop")
                    .font(Typography.display(22)).foregroundStyle(Palette.cream)
                Text("Press and hold - it comes up slowly.")
                    .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.7))
                holdButton
            }
            .multilineTextAlignment(.center)
        }
    }

    private var holdButton: some View {
        Text(holding ? "Developing…" : "Hold to develop")
            .font(Typography.sans(15, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 22).padding(.vertical, 10)
            .background(Palette.amber, in: Capsule())
            .scaleEffect(holding ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: holding)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !holding { startHold() } }
                    .onEnded { _ in holding = false }
            )
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
                        .padding(10).background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove print")

                if developed {
                    saveOptionsMenu

                    Button { Task { await savePrint() } } label: {
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
                    .disabled(isSaving)
                    .accessibilityLabel("Save print to Photos")
                }

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
        .padding(.horizontal, 20)
        .safeAreaPadding(.top, 6)
        .confirmationDialog(
            "Remove this print from your Drawer?",
            isPresented: $confirmRemove,
            titleVisibility: .visible
        ) {
            Button("Remove print", role: .destructive) { removePrint() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will not return the shot.")
        }
    }

    private var saveOptionsMenu: some View {
        Menu {
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

    // MARK: Develop logic

    private func setup() async {
        progress = photo.developProgress
        if ProcessInfo.processInfo.arguments.contains("-devMid") { progress = 0.4 }
        image = PhotoStore.loadImageData(named: photo.rawImageName).flatMap(UIImage.init(data:))

        // Play the gesture demo once, only for a still-blank print.
        if !developed {
            try? await Task.sleep(for: .milliseconds(350))
            demo += 1
        }

        guard usesShake else { return }
        shake.onShake = { energy in advance(by: energy * 0.045) }
        shake.start()
    }

    /// Ramp from a hold: advance smoothly while the button is pressed.
    private func startHold() {
        holding = true
        Task {
            while holding && progress < 1 {
                advance(by: 0.012)
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func advance(by amount: Double) {
        guard progress < 1 else { return }
        progress = min(1, progress + amount)
        rattle()
        if progress >= 1 { finish() }
    }

    // Throttled haptic "rattle" while developing.
    @State private var lastHaptic = Date.distantPast
    private func rattle() {
        let now = Date()
        guard now.timeIntervalSince(lastHaptic) > 0.09 else { return }
        lastHaptic = now
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    private func finish() {
        holding = false
        shake.stop()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        photo.isDeveloped = true
        photo.developProgress = 1
        try? context.save()
        ReviewPrompter.shared.recordDevelopedPrint()
    }

    private func removePrint() {
        holding = false
        shake.stop()
        PhotoStore.deleteImages(for: photo)
        context.delete(photo)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    @MainActor
    private func savePrint() async {
        guard developed, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let style: PhotoLibrarySaveStyle = saveIncludesPostcardFrame ? .postcardFrame : .photoOnly
        let result = await PhotoLibrarySaver.saveDeveloped(photo, style: style)
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
            return style == .postcardFrame ? "Saved postcard to Photos." : "Saved photo to Photos."
        case .noDevelopedPhotos:
            return "Develop this print before saving."
        case .denied:
            return "Allow Photos access to save prints."
        case .failed:
            return "Could not save. Try again."
        }
    }
}

/// Animatable value for the one-time gesture demo.
private struct DemoMotion: Animatable {
    var angle: Double = 0
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
}
