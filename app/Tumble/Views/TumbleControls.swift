import SwiftUI
import TumbleKit

// Shared controls for the 3.1 interface. Every control draws its visual at
// the size the design calls for, but keeps a 44-point hit region.

/// Subtle press feedback for custom-drawn buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// The amber call to action. `fill` stretches it to the available width.
struct PrimaryButtonStyle: ButtonStyle {
    var fill = true
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        StyledButtonBody(configuration: configuration, fill: fill, height: height, primary: true)
    }
}

/// A quiet raised button that sits beside or below a primary action.
struct SecondaryButtonStyle: ButtonStyle {
    var fill = true
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        StyledButtonBody(configuration: configuration, fill: fill, height: height, primary: false)
    }
}

private struct StyledButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let fill: Bool
    let height: CGFloat
    let primary: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(primary ? Palette.ink : Palette.textPrimary)
            .padding(.horizontal, 16)
            .frame(maxWidth: fill ? .infinity : nil)
            .frame(height: height)
            .background(
                primary ? Palette.amber : Palette.surfaceRaised,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                if !primary {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline)
                }
            }
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
            .contentShape(Rectangle())
    }
}

/// A round glyph button for top bars and canvas overlays.
struct IconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var action: () -> Void

    init(_ systemName: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textPrimary)
                .frame(
                    width: EditorChromeMetrics.iconButtonVisual,
                    height: EditorChromeMetrics.iconButtonVisual
                )
                .background(Palette.surfaceRaised.opacity(0.92), in: Circle())
                .overlay(Circle().stroke(Palette.hairline))
                .frame(
                    width: EditorChromeMetrics.minimumHitTarget,
                    height: EditorChromeMetrics.minimumHitTarget
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// One header pattern for editing screens and the camera: a leading control,
/// an optional centered title, and a trailing control.
struct EditorTopBar<Leading: View, Trailing: View>: View {
    var title: String?
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            if let title {
                Text(title)
                    .font(Typography.navTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 96)
                    .accessibilityAddTraits(.isHeader)
            }
            HStack(spacing: 8) {
                leading
                Spacer(minLength: 0)
                trailing
            }
        }
        .padding(.horizontal, EditorChromeMetrics.horizontalPadding)
        .frame(height: EditorChromeMetrics.topBarHeight)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// A two-or-three-way switch drawn as a sliding pill. Each segment remains a
/// separate button so it can be found and activated by VoiceOver and tests.
struct SegmentedPill<Value: Hashable>: View {
    let options: [Value]
    let selection: Value
    let title: (Value) -> String
    var icon: ((Value) -> String)?
    let onSelect: (Value) -> Void

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    guard option != selection else { return }
                    Haptics.selection()
                    withAnimation(Motion.spring(reduceMotion: reduceMotion)) { onSelect(option) }
                } label: {
                    HStack(spacing: 6) {
                        if let icon { Image(systemName: icon(option)) }
                        Text(title(option))
                    }
                    .font(Typography.headline)
                    .foregroundStyle(selected ? Palette.textPrimary : Palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: EditorChromeMetrics.segmentVisualHeight)
                    .background {
                        if selected {
                            Capsule()
                                .fill(Palette.cream.opacity(0.14))
                                .matchedGeometryEffect(id: "selection", in: namespace)
                        }
                    }
                    .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title(option))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 4)
        .background(
            Capsule()
                .fill(Palette.surfaceRaised)
                .frame(height: EditorChromeMetrics.segmentVisualHeight + 6)
        )
    }
}

/// A selectable capsule for presets and filters.
struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.captionEmphasized)
                .foregroundStyle(selected ? Palette.ink : Palette.textPrimary.opacity(0.86))
                .lineLimit(1)
                .padding(.horizontal, 13)
                .frame(height: EditorChromeMetrics.chipVisualHeight)
                .background(selected ? Palette.cream : Palette.surfaceRaised, in: Capsule())
                .overlay(Capsule().stroke(selected ? Color.clear : Palette.hairline))
                .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
