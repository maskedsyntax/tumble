import SwiftUI
import TumbleKit
import UIKit

/// Direct-manipulation crop. Shows the whole (straightened) photograph with
/// the crop drawn on top: drag inside to move it, drag a corner to resize
/// it, and the preset decides whether the aspect is locked.
///
/// `base` is the film-rendered image after quarter turns but before
/// straightening or cropping. Straightening is drawn live with a rotation
/// and the same inscribed scale the renderer uses, so the frame shown here
/// is exactly the region that will be exported.
struct CropCanvas: View {
    let base: UIImage?
    @Binding var recipe: EditRecipe
    var onInteraction: (Bool) -> Void = { _ in }

    @State private var dragStart: NormalizedRect?
    @State private var interacting = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var imageAspect: Double {
        guard let base, base.size.height > 0 else { return 1 }
        return base.size.width / base.size.height
    }

    private var lockedAspect: Double? {
        CropGeometry.lockedAspect(for: recipe.cropPreset, imageAspect: imageAspect)
    }

    /// The crop in top-left-origin space for drawing.
    private var rect: NormalizedRect {
        NormalizedRect(stored: CropGeometry.effectiveCrop(for: recipe, imageAspect: imageAspect))
    }

    var body: some View {
        GeometryReader { proxy in
            let frame = fittedFrame(in: proxy.size)
            ZStack {
                if let base {
                    let scale = CropGeometry.inscribedScale(width: imageAspect, height: 1, degrees: recipe.straighten)
                    Image(uiImage: base)
                        .resizable()
                        .frame(width: frame.width, height: frame.height)
                        .rotationEffect(.degrees(recipe.straighten))
                        .scaleEffect(1 / scale)
                        .frame(width: frame.width, height: frame.height)
                        .clipped()
                    overlay(size: frame)
                } else {
                    ProgressView().tint(Palette.amber)
                }
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func fittedFrame(in size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        if size.width / size.height > imageAspect {
            return CGSize(width: size.height * imageAspect, height: size.height)
        }
        return CGSize(width: size.width, height: size.width / imageAspect)
    }

    // MARK: Overlay

    @ViewBuilder
    private func overlay(size: CGSize) -> some View {
        let crop = rect.cgRect(in: size)
        ZStack(alignment: .topLeading) {
            // Dim everything outside the crop.
            Path { path in
                path.addRect(CGRect(origin: .zero, size: size))
                path.addRect(crop)
            }
            .fill(Color.black.opacity(0.58), style: FillStyle(eoFill: true))
            .allowsHitTesting(false)

            // Thirds grid while adjusting.
            Path { path in
                for step in 1...2 {
                    let x = crop.minX + crop.width * CGFloat(step) / 3
                    let y = crop.minY + crop.height * CGFloat(step) / 3
                    path.move(to: CGPoint(x: x, y: crop.minY))
                    path.addLine(to: CGPoint(x: x, y: crop.maxY))
                    path.move(to: CGPoint(x: crop.minX, y: y))
                    path.addLine(to: CGPoint(x: crop.maxX, y: y))
                }
            }
            .stroke(Color.white.opacity(interacting ? 0.42 : 0), lineWidth: 0.5)
            .allowsHitTesting(false)

            Rectangle()
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                .frame(width: crop.width, height: crop.height)
                .offset(x: crop.minX, y: crop.minY)
                .allowsHitTesting(false)

            // Move: the crop interior.
            Color.clear
                .contentShape(Rectangle())
                .frame(width: crop.width, height: crop.height)
                .offset(x: crop.minX, y: crop.minY)
                .gesture(moveGesture(size: size))
                .accessibilityElement()
                .accessibilityLabel("Crop")
                .accessibilityValue(accessibilityValue)
                .accessibilityActions { accessibilityControls }

            ForEach(Corner.allCases, id: \.self) { corner in
                CornerHandle(corner: corner)
                    .frame(width: EditorChromeMetrics.minimumHitTarget, height: EditorChromeMetrics.minimumHitTarget)
                    .contentShape(Rectangle())
                    .position(corner.point(in: crop))
                    .gesture(resizeGesture(corner, size: size))
                    .accessibilityHidden(true)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(.easeOut(duration: 0.15), value: interacting)
    }

    // MARK: Gestures

    private func moveGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let start = begin()
                var next = start
                next.x = start.x + value.translation.width / max(1, size.width)
                next.y = start.y + value.translation.height / max(1, size.height)
                commit(next.keptInside, animated: false)
            }
            .onEnded { _ in end() }
    }

    private func resizeGesture(_ corner: Corner, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = begin()
                let anchor = corner.opposite.normalizedPoint(of: start)
                let moved = corner.normalizedPoint(of: start)
                let point = CGPoint(
                    x: min(1, max(0, moved.x + value.translation.width / max(1, size.width))),
                    y: min(1, max(0, moved.y + value.translation.height / max(1, size.height)))
                )
                commit(resized(anchor: anchor, toward: point, corner: corner), animated: false)
            }
            .onEnded { _ in end() }
    }

    private func begin() -> NormalizedRect {
        if let dragStart { return dragStart }
        let start = rect
        dragStart = start
        interacting = true
        onInteraction(true)
        return start
    }

    private func end() {
        dragStart = nil
        interacting = false
        onInteraction(false)
    }

    /// A rectangle from a fixed `anchor` toward the dragged `point`, held to
    /// the locked aspect and to the image bounds.
    private func resized(anchor: CGPoint, toward point: CGPoint, corner: Corner) -> NormalizedRect {
        let growsRight = corner.isTrailing
        let growsDown = corner.isBottom
        let maxWidth = growsRight ? 1 - anchor.x : anchor.x
        let maxHeight = growsDown ? 1 - anchor.y : anchor.y
        var width = abs(point.x - anchor.x)
        var height = abs(point.y - anchor.y)
        let minimum = 0.12

        if let lockedAspect {
            // Normalized height per unit of normalized width for this aspect.
            let ratio = imageAspect / lockedAspect
            // Average the horizontal and vertical proposals so dragging along
            // either axis (or diagonally) resizes smoothly.
            width = (width + height / ratio) / 2
            width = min(width, maxWidth, maxHeight / ratio)
            width = max(width, minimum, minimum / ratio)
            width = min(width, maxWidth, maxHeight / ratio)
            height = width * ratio
        } else {
            width = min(max(width, minimum), maxWidth)
            height = min(max(height, minimum), maxHeight)
        }
        return NormalizedRect(
            x: growsRight ? anchor.x : anchor.x - width,
            y: growsDown ? anchor.y : anchor.y - height,
            width: width,
            height: height
        )
    }

    private func commit(_ next: NormalizedRect, animated: Bool) {
        let stored = next.stored
        guard stored != recipe.crop else { return }
        if animated {
            withAnimation(Motion.spring(reduceMotion: reduceMotion)) { recipe.crop = stored }
        } else {
            recipe.crop = stored
        }
    }

    // MARK: Accessibility

    private var accessibilityValue: String {
        let r = rect
        return "\(Int((r.width * 100).rounded())) percent wide, \(Int((r.height * 100).rounded())) percent tall"
    }

    @ViewBuilder
    private var accessibilityControls: some View {
        Button("Move left") { nudge(dx: -0.05, dy: 0) }
        Button("Move right") { nudge(dx: 0.05, dy: 0) }
        Button("Move up") { nudge(dx: 0, dy: -0.05) }
        Button("Move down") { nudge(dx: 0, dy: 0.05) }
        Button("Larger") { scale(by: 1.1) }
        Button("Smaller") { scale(by: 0.9) }
    }

    private func nudge(dx: Double, dy: Double) {
        var next = rect
        next.x += dx
        next.y += dy
        commit(next.keptInside, animated: false)
    }

    private func scale(by factor: Double) {
        let current = rect
        let center = CGPoint(x: current.x + current.width / 2, y: current.y + current.height / 2)
        var width = current.width * factor
        var height = current.height * factor
        let limit = min(1 / width, 1 / height, 1)
        if limit < 1 {
            width *= limit
            height *= limit
        }
        width = max(width, 0.12)
        height = max(height, 0.12)
        let next = NormalizedRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
        commit(next.keptInside, animated: false)
    }
}

/// A normalized rectangle with a top-left origin, as drawn on screen.
/// The recipe stores crops with a bottom-left origin (the renderer's space).
struct NormalizedRect: Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(stored crop: NormalizedCrop) {
        self.init(x: crop.x, y: 1 - crop.y - crop.height, width: crop.width, height: crop.height)
    }

    var stored: NormalizedCrop {
        NormalizedCrop(x: x, y: 1 - y - height, width: width, height: height)
    }

    var keptInside: NormalizedRect {
        var next = self
        next.width = min(1, width)
        next.height = min(1, height)
        next.x = min(1 - next.width, max(0, x))
        next.y = min(1 - next.height, max(0, y))
        return next
    }

    func cgRect(in size: CGSize) -> CGRect {
        CGRect(x: x * size.width, y: y * size.height, width: width * size.width, height: height * size.height)
    }
}

private enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var isTrailing: Bool { self == .topTrailing || self == .bottomTrailing }
    var isBottom: Bool { self == .bottomLeading || self == .bottomTrailing }

    var opposite: Corner {
        switch self {
        case .topLeading: .bottomTrailing
        case .topTrailing: .bottomLeading
        case .bottomLeading: .topTrailing
        case .bottomTrailing: .topLeading
        }
    }

    func point(in rect: CGRect) -> CGPoint {
        CGPoint(x: isTrailing ? rect.maxX : rect.minX, y: isBottom ? rect.maxY : rect.minY)
    }

    func normalizedPoint(of rect: NormalizedRect) -> CGPoint {
        CGPoint(x: isTrailing ? rect.x + rect.width : rect.x, y: isBottom ? rect.y + rect.height : rect.y)
    }
}

/// An L-shaped corner bracket centered in its hit area.
private struct CornerHandle: View {
    let corner: Corner
    private let length: CGFloat = 18
    private let thickness: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let c = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let dx: CGFloat = corner.isTrailing ? -length : length
            let dy: CGFloat = corner.isBottom ? -length : length
            Path { path in
                path.move(to: CGPoint(x: c.x + dx, y: c.y))
                path.addLine(to: c)
                path.addLine(to: CGPoint(x: c.x, y: c.y + dy))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: thickness, lineCap: .square, lineJoin: .miter))
            .shadow(color: .black.opacity(0.35), radius: 2)
        }
    }
}

/// A horizontal tick ruler for fine rotation. Drag to turn, tap the
/// readout to return to level. Ticks every degree, longer every five.
struct StraightenRuler: View {
    @Binding var degrees: Double
    var onInteraction: (Bool) -> Void = { _ in }

    @State private var dragStartValue: Double?
    private let pointsPerDegree: CGFloat = 7

    var body: some View {
        VStack(spacing: 6) {
            Button {
                guard degrees != 0 else { return }
                Haptics.soft()
                degrees = 0
            } label: {
                Text(readout)
                    .font(Typography.captionEmphasized.monospacedDigit())
                    .foregroundStyle(degrees == 0 ? Palette.textSecondary : Palette.amber)
                    .frame(minWidth: 64, minHeight: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

            GeometryReader { proxy in
                let mid = proxy.size.width / 2
                Canvas { context, size in
                    let limit = Int(CropGeometry.straightenLimit)
                    for tick in -limit...limit {
                        let x = mid + (CGFloat(tick) - CGFloat(degrees)) * pointsPerDegree
                        guard x > -2, x < size.width + 2 else { continue }
                        let major = tick % 5 == 0
                        let height: CGFloat = tick == 0 ? 18 : (major ? 13 : 7)
                        let rect = CGRect(x: x - 0.5, y: (size.height - height) / 2, width: 1, height: height)
                        let opacity = major ? 0.7 : 0.35
                        context.fill(Path(rect), with: .color(Palette.cream.opacity(opacity)))
                    }
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.18),
                            .init(color: .black, location: 0.82),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    Capsule()
                        .fill(Palette.amber)
                        .frame(width: 2, height: 24)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if dragStartValue == nil {
                                dragStartValue = degrees
                                onInteraction(true)
                            }
                            let proposed = (dragStartValue ?? 0) - Double(value.translation.width / pointsPerDegree)
                            let next = CropGeometry.clampStraighten((proposed * 10).rounded() / 10)
                            if (degrees < 0 && next >= 0) || (degrees > 0 && next <= 0) || abs(next) == CropGeometry.straightenLimit {
                                if next != degrees { Haptics.soft() }
                            }
                            degrees = next
                        }
                        .onEnded { _ in
                            dragStartValue = nil
                            if abs(degrees) < 0.4 { degrees = 0 }
                            onInteraction(false)
                        }
                )
            }
            .frame(height: 30)
        }
        .accessibilityElement()
        .accessibilityLabel("Straighten")
        .accessibilityValue(readout)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: degrees = CropGeometry.clampStraighten(degrees + 1)
            case .decrement: degrees = CropGeometry.clampStraighten(degrees - 1)
            @unknown default: break
            }
        }
    }

    private var readout: String {
        let value = (degrees * 10).rounded() / 10
        if value == 0 { return "0°" }
        let text = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        return text.replacingOccurrences(of: "-", with: "−") + "°"
    }
}
