import SwiftUI
import SwiftData
import TumbleKit

/// The Drawer as a loosely scattered, overlapping pile of prints — never a
/// grid. Newest sits on top. This is the app's home surface: shots you take
/// (pulled from the island camera) land here. Tap an undeveloped print to shake
/// it to life; tap a developed one to pull it out full-screen.
struct DrawerPile: View {
    let photos: [Photo]
    let onSelect: (Photo) -> Void

    var body: some View {
        if photos.isEmpty {
            emptyDrawer
        } else {
            GeometryReader { geo in
                // Newest ~15 prints. Arranged as one print in the middle with the
                // rest surrounding it on a regular polygon (see `placements`).
                let shown = Array(photos.prefix(15))
                let places = placements(count: shown.count, size: geo.size)

                ZStack {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, photo in
                        let p = places[index]
                        DrawerPrint(photo: photo, width: p.width)
                            .position(p.center)
                            .rotationEffect(.degrees(photo.rotation * 0.5))
                            .zIndex(p.z)
                            .onTapGesture { onSelect(photo) }
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: photos.count)
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
    private func placements(count n: Int, size: CGSize) -> [Placement] {
        let W = size.width, H = size.height
        let cx = W / 2, cy = H * 0.5

        switch n {
        case 0:
            return []
        case 1:
            return [Placement(center: CGPoint(x: cx, y: cy), width: W * 0.50, z: 0)]
        case 2:
            let w = W * 0.46
            return [
                Placement(center: CGPoint(x: cx - W * 0.21, y: cy), width: w, z: 1),
                Placement(center: CGPoint(x: cx + W * 0.21, y: cy), width: w, z: 0),
            ]
        case 3:
            let w = W * 0.44
            return [
                Placement(center: CGPoint(x: cx, y: H * 0.27), width: w, z: 2),
                Placement(center: CGPoint(x: cx, y: H * 0.50), width: w, z: 1),
                Placement(center: CGPoint(x: cx, y: H * 0.73), width: w, z: 0),
            ]
        default:
            let k = n - 1 // surrounding prints
            let rx = W * 0.32
            let ry = H * 0.27
            let centerW = W * 0.40
            let surroundW = W * min(0.38, max(0.22, 0.86 / Double(k).squareRoot()))

            var out: [Placement] = [
                // Newest sits in the middle, on top.
                Placement(center: CGPoint(x: cx, y: cy), width: centerW, z: Double(n)),
            ]
            for i in 0..<k {
                // Start at the top (−90°) and step evenly around the ring.
                let angle = (-90.0 + Double(i) * 360.0 / Double(k)) * .pi / 180
                let x = cx + rx * CGFloat(cos(angle))
                let y = cy + ry * CGFloat(sin(angle))
                out.append(Placement(center: CGPoint(x: x, y: y), width: surroundW, z: Double(k - i)))
            }
            return out
        }
    }

    private var emptyDrawer: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray").font(.system(size: 40, weight: .thin))
                .foregroundStyle(Palette.cream.opacity(0.4))
            Text("Nothing in the drawer yet.")
                .font(Typography.display(20)).foregroundStyle(Palette.cream)
            Text("Pull the camera down from the top, take a shot,\nthen shake it to develop.")
                .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
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
