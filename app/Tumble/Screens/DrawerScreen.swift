import SwiftUI
import SwiftData
import TumbleKit

/// The Drawer — a loosely scattered, overlapping pile of prints, never a grid.
/// Newest sits on top. Tap an undeveloped print to shake it to life; tap a
/// developed one to pull it out full-screen.
struct DrawerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var selected: Photo?

    private var developedCount: Int { photos.filter(\.isDeveloped).count }

    var body: some View {
        ZStack {
            GraincoreBackground()

            VStack(alignment: .leading, spacing: 4) {
                header
                pile
            }
            .padding(.top, 8)

            closeButton
        }
        .fullScreenCover(item: $selected) { photo in
            PrintStage(photo: photo, developed: photos.filter(\.isDeveloped))
        }
        .task {
            // Debug: jump straight to developing the first blank print.
            if ProcessInfo.processInfo.arguments.contains("-develop") {
                selected = photos.first { !$0.isDeveloped }
            } else if ProcessInfo.processInfo.arguments.contains("-detail") {
                selected = photos.first { $0.isDeveloped }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Drawer").font(Typography.display(30)).foregroundStyle(Palette.cream)
            Text("\(developedCount) developed · \(photos.count) in the drawer")
                .font(Typography.sans(12))
                .foregroundStyle(Palette.cream.opacity(0.55))
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder private var pile: some View {
        if photos.isEmpty {
            emptyDrawer
        } else {
            GeometryReader { geo in
                let printW = geo.size.width * 0.46
                ZStack {
                    // Only the top ~15 prints composite live; the rest sit
                    // beneath as a "dig" stack (cheap solid stand-ins).
                    ForEach(Array(photos.prefix(15).enumerated()), id: \.element.id) { index, photo in
                        DrawerPrint(photo: photo, width: printW)
                            .position(
                                // Keep centers within a safe band so no print
                                // clips off-screen, while staying loose.
                                x: geo.size.width * (0.28 + (photo.scatterX / 100) * 0.42),
                                y: geo.size.height * (0.14 + (photo.scatterY / 100) * 0.74)
                            )
                            .rotationEffect(.degrees(photo.rotation))
                            .zIndex(Double(photos.count - index))
                            .onTapGesture { selected = photo }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private var emptyDrawer: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray").font(.system(size: 40, weight: .thin))
                .foregroundStyle(Palette.cream.opacity(0.4))
            Text("Nothing in the drawer yet.")
                .font(Typography.display(20)).foregroundStyle(Palette.cream)
            Text("Take a shot, then shake to develop it.")
                .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.cream)
                        .padding(10)
                        .background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
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
