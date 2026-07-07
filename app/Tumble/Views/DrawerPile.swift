import SwiftUI
import SwiftData
import TumbleKit

/// The Drawer as a loosely scattered, overlapping pile of prints - never a
/// grid. Newest sits on top. This is the app's home surface: shots you take
/// (pulled from the island camera) land here. Tap an undeveloped print to shake
/// it to life; tap a developed one to pull it out full-screen.
struct DrawerPile: View {
    let photos: [Photo]
    let onSelect: (Photo) -> Void
    let previewLimit: Int
    let emptyTitle: String
    let emptySubtitle: String
    let resetToken: Int
    let onResetAvailabilityChange: (Bool) -> Void

    @State private var spread: CGFloat = 0
    @State private var pinchBaseSpread: CGFloat = 0
    @State private var isPinching = false
    @State private var slotOrder: [UUID] = []
    @State private var activeDrag: UUID?
    @State private var dragStartCenter: CGPoint?
    @State private var activeCenter: CGPoint?
    @State private var recentlyDragged: UUID?

    private let dragThreshold: CGFloat = 0.22

    init(
        photos: [Photo],
        previewLimit: Int = 15,
        emptyTitle: String = "Nothing in the drawer yet.",
        emptySubtitle: String = "Pull the camera down from the top, take a shot,\nthen shake it to develop.",
        resetToken: Int = 0,
        onResetAvailabilityChange: @escaping (Bool) -> Void = { _ in },
        onSelect: @escaping (Photo) -> Void
    ) {
        self.photos = photos
        self.previewLimit = previewLimit
        self.emptyTitle = emptyTitle
        self.emptySubtitle = emptySubtitle
        self.resetToken = resetToken
        self.onResetAvailabilityChange = onResetAvailabilityChange
        self.onSelect = onSelect
    }

    var body: some View {
        if photos.isEmpty {
            emptyDrawer
                .onAppear { onResetAvailabilityChange(false) }
        } else {
            GeometryReader { geo in
                // Newest preview prints. Arranged as one print in the middle with the
                // rest surrounding it on a regular polygon (see `placements`).
                let shown = Array(photos.prefix(previewLimit))
                let shownIDs = shown.map(\.id)
                let arranged = orderedPhotos(from: shown)
                let canResetLayout = canReset(shownIDs: shownIDs)
                let places = placements(count: arranged.count, size: geo.size, spread: spread)

                ZStack {
                    ForEach(Array(arranged.enumerated()), id: \.element.id) { index, photo in
                        let p = places[index]
                        let lifted = activeDrag == photo.id
                        let displayCenter = lifted ? (activeCenter ?? p.center) : p.center
                        let wobble = isPinching ? sin(Double(index) * 1.7) * 2.2 * Double(spread) : 0

                        DrawerPrint(photo: photo, width: p.width)
                            .position(displayCenter)
                            .rotationEffect(.degrees(photo.rotation * 0.5 + wobble))
                            .scaleEffect(lifted ? 1.055 : 1)
                            .shadow(color: .black.opacity(lifted ? 0.34 : 0),
                                    radius: lifted ? 18 : 0,
                                    y: lifted ? 9 : 0)
                            .zIndex(lifted ? 999 : p.z)
                            .onTapGesture {
                                guard recentlyDragged != photo.id else { return }
                                onSelect(photo)
                            }
                            .simultaneousGesture(
                                printDragGesture(
                                    for: photo,
                                    placements: places,
                                    shownIDs: shownIDs,
                                    canvas: geo.size
                                )
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(pinchGesture)
                .onAppear {
                    pruneSlotOrder(to: shownIDs)
                    onResetAvailabilityChange(canResetLayout)
                }
                .onChange(of: shownIDs) { _, ids in pruneSlotOrder(to: ids) }
                .onChange(of: canResetLayout) { _, canReset in
                    onResetAvailabilityChange(canReset)
                }
                .onChange(of: resetToken) { _, _ in resetLayout() }
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: photos.count)
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: slotOrder)
                .animation(.spring(response: 0.34, dampingFraction: 0.84), value: spread)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: activeDrag)
            }
        }
    }

    private struct Placement {
        var center: CGPoint
        var width: CGFloat
        var z: Double
    }

    /// Lays out `count` prints (index 0 = newest).
    ///
    /// - 1: a single print in the middle.
    /// - 2: a horizontal pair.
    /// - 3: a vertical trio.
    /// - 4+: the newest print in the middle, the remaining `count - 1` on a
    ///   regular polygon around it (a vertex at the top, so the ring reads as an
    ///   upright triangle / diamond / pentagon … as the count grows).
    private func placements(count n: Int, size: CGSize, spread: CGFloat) -> [Placement] {
        let W = size.width, H = size.height
        let cx = W / 2, cy = H * 0.5
        let spacing = 1 + spread * 0.55
        let sizeEase = 1 - spread * 0.06

        switch n {
        case 0:
            return []
        case 1:
            return [Placement(center: CGPoint(x: cx, y: cy), width: W * 0.50, z: 0)]
        case 2:
            let w = W * 0.46 * sizeEase
            return [
                Placement(center: CGPoint(x: cx - W * 0.21 * spacing, y: cy), width: w, z: 1),
                Placement(center: CGPoint(x: cx + W * 0.21 * spacing, y: cy), width: w, z: 0),
            ]
        case 3:
            let w = W * 0.44 * sizeEase
            return [
                Placement(center: CGPoint(x: cx, y: cy - H * 0.23 * spacing), width: w, z: 2),
                Placement(center: CGPoint(x: cx, y: H * 0.50), width: w, z: 1),
                Placement(center: CGPoint(x: cx, y: cy + H * 0.23 * spacing), width: w, z: 0),
            ]
        default:
            let k = n - 1 // surrounding prints
            let rx = W * (0.30 + 0.16 * spread)
            let ry = H * (0.25 + 0.13 * spread)
            let centerW = W * 0.40 * sizeEase
            let surroundW = W * min(0.38, max(0.22, 0.86 / Double(k).squareRoot())) * sizeEase

            var out: [Placement] = [
                // Newest sits in the middle, on top.
                Placement(center: CGPoint(x: cx, y: cy), width: centerW, z: Double(n)),
            ]
            for i in 0..<k {
                // Start at the top (−90°) and step evenly around the ring.
                let angle = (-90.0 + Double(i) * 360.0 / Double(k)) * .pi / 180
                let raw = CGPoint(
                    x: cx + rx * CGFloat(cos(angle)),
                    y: cy + ry * CGFloat(sin(angle))
                )
                out.append(Placement(center: clamped(raw, in: size, margin: surroundW * 0.52),
                                     width: surroundW,
                                     z: Double(k - i)))
            }
            return out
        }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                isPinching = true
                spread = clamp(pinchBaseSpread + (value - 1) * 1.25, 0, 1)
            }
            .onEnded { value in
                let next = clamp(pinchBaseSpread + (value - 1) * 1.25, 0, 1)
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    spread = next
                    pinchBaseSpread = next
                    isPinching = false
                }
            }
    }

    private func orderedPhotos(from shown: [Photo]) -> [Photo] {
        let orderedIDs = normalizedSlotIDs(for: shown.map(\.id))
        let lookup = Dictionary(uniqueKeysWithValues: shown.map { ($0.id, $0) })
        return orderedIDs.compactMap { lookup[$0] }
    }

    private func normalizedSlotIDs(for shownIDs: [UUID]) -> [UUID] {
        guard !slotOrder.isEmpty else { return shownIDs }

        var seen = Set<UUID>()
        var ordered: [UUID] = []
        for id in slotOrder where shownIDs.contains(id) && seen.insert(id).inserted {
            ordered.append(id)
        }
        for id in shownIDs where seen.insert(id).inserted {
            ordered.append(id)
        }
        return ordered
    }

    private func canReset(shownIDs: [UUID]) -> Bool {
        spread > 0.05 || normalizedSlotIDs(for: shownIDs) != shownIDs
    }

    private func pruneSlotOrder(to shownIDs: [UUID]) {
        if let activeDrag, !shownIDs.contains(activeDrag) {
            self.activeDrag = nil
            dragStartCenter = nil
            activeCenter = nil
        }

        guard !slotOrder.isEmpty else { return }
        let normalized = normalizedSlotIDs(for: shownIDs)
        slotOrder = normalized == shownIDs ? [] : normalized
    }

    private func resetLayout() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            spread = 0
            pinchBaseSpread = 0
            isPinching = false
            slotOrder = []
            activeDrag = nil
            dragStartCenter = nil
            activeCenter = nil
        }
    }

    private func printDragGesture(
        for photo: Photo,
        placements: [Placement],
        shownIDs: [UUID],
        canvas: CGSize
    ) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard spread > dragThreshold else { return }
                let currentOrder = normalizedSlotIDs(for: shownIDs)
                guard let currentIndex = currentOrder.firstIndex(of: photo.id),
                      placements.indices.contains(currentIndex)
                else { return }

                if activeDrag != photo.id {
                    activeDrag = photo.id
                    dragStartCenter = placements[currentIndex].center
                    activeCenter = placements[currentIndex].center
                }

                guard let dragStartCenter else { return }
                let margin = placements[currentIndex].width * 0.52
                let proposedCenter = CGPoint(
                    x: dragStartCenter.x + value.translation.width,
                    y: dragStartCenter.y + value.translation.height
                )
                let currentCenter = clamped(proposedCenter, in: canvas, margin: margin)
                var nextOrder = currentOrder
                let targetIndex = swapTargetIndex(
                    for: currentCenter,
                    placements: placements,
                    currentIndex: currentIndex
                )

                if targetIndex != currentIndex {
                    nextOrder.swapAt(currentIndex, targetIndex)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        slotOrder = nextOrder == shownIDs ? [] : nextOrder
                    }
                } else if slotOrder.isEmpty {
                    slotOrder = nextOrder
                }

                activeCenter = currentCenter
            }
            .onEnded { value in
                guard spread > dragThreshold, activeDrag == photo.id else { return }
                let moved = hypot(value.translation.width, value.translation.height) > 4
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    activeDrag = nil
                    dragStartCenter = nil
                    activeCenter = nil
                }
                if moved {
                    recentlyDragged = photo.id
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(180))
                        if recentlyDragged == photo.id {
                            recentlyDragged = nil
                        }
                    }
                }
            }
    }

    private func swapTargetIndex(
        for center: CGPoint,
        placements: [Placement],
        currentIndex: Int
    ) -> Int {
        guard placements.indices.contains(currentIndex), placements.count > 1 else {
            return currentIndex
        }

        let ownDistance = distance(center, placements[currentIndex].center)
        var bestIndex = currentIndex
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for index in placements.indices where index != currentIndex {
            let candidateDistance = distance(center, placements[index].center)
            if candidateDistance < bestDistance {
                bestDistance = candidateDistance
                bestIndex = index
            }
        }

        let threshold = clamp(max(placements[currentIndex].width, placements[bestIndex].width) * 0.7, 62, 145)
        return bestDistance + 12 < ownDistance && bestDistance < threshold ? bestIndex : currentIndex
    }

    private var emptyDrawer: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray").font(.system(size: 40, weight: .thin))
                .foregroundStyle(Palette.cream.opacity(0.4))
            Text(emptyTitle)
                .font(Typography.display(20)).foregroundStyle(Palette.cream)
            Text(emptySubtitle)
                .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
    min(max(value, lower), upper)
}

private func clamped(_ point: CGPoint, in size: CGSize, margin: CGFloat) -> CGPoint {
    CGPoint(
        x: clamp(point.x, margin, size.width - margin),
        y: clamp(point.y, margin, size.height - margin)
    )
}

private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    hypot(a.x - b.x, a.y - b.y)
}

/// A print in the pile that lazily loads its image bytes off disk.
private struct DrawerPrint: View {
    let photo: Photo
    let width: CGFloat
    @State private var image: UIImage?

    var body: some View {
        PrintView(
            image: image,
            isDeveloped: photo.isDeveloped,
            developProgress: photo.isDeveloped ? 1 : photo.developProgress,
            age: photo.ageFraction(),
            caption: photo.caption,
            width: width
        )
        .task(id: photo.id) {
            let name = photo.developedImageName ?? photo.rawImageName
            image = PhotoStore.loadImageData(named: name).flatMap(UIImage.init(data:))
        }
        .accessibilityElement()
        .accessibilityLabel(
            photo.isDeveloped
                ? "Developed print from \(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))"
                : "Undeveloped shot. Open to shake it to develop."
        )
        .accessibilityAddTraits(.isButton)
    }
}
