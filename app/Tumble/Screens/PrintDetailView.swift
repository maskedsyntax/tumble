import SwiftUI
import TumbleKit

/// A developed print pulled out of the Drawer, full-screen. Riffle left/right
/// through the rest of the developed pile; swipe down to toss it back in.
struct PrintDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let developed: [Photo]
    @State private var index: Int
    @State private var dragY: CGFloat = 0

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
            closeButton
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

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
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
