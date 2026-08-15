import SwiftUI
import SwiftData
import TumbleKit

/// The look shelf: choose the film stock a single print is developed with.
/// Thumbnails render the *actual* print through each stock, so the choice you
/// see is the choice you get. Locked packs show a badge and route to the
/// paywall rather than applying.
struct LookPickerView: View {
    let photo: Photo
    /// Called after the stock changes, so the owner can re-render its preview.
    var onChange: () -> Void = {}
    /// Called when a locked stock is tapped, with its pack to sell.
    var onLocked: (FilmPack) -> Void = { _ in }

    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var context
    @State private var rawData: Data?

    private var selectedID: String { photo.filmStock.id }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(FilmStockCatalog.groupedByPack, id: \.pack.id) { group in
                    packColumn(group.pack, stocks: group.stocks)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .task(id: photo.id) {
            rawData = PhotoStore.loadImageData(named: photo.rawImageName)
        }
    }

    private func packColumn(_ pack: FilmPack, stocks: [FilmStock]) -> some View {
        let owned = app.purchases.ownsPack(pack.id)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text(pack.name)
                    .font(Typography.sans(10.5, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.amber)
                if !owned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Palette.cream.opacity(0.5))
                }
            }

            HStack(spacing: 9) {
                ForEach(stocks) { stock in
                    thumbnail(stock, locked: !owned, pack: pack)
                }
            }
        }
    }

    private func thumbnail(_ stock: FilmStock, locked: Bool, pack: FilmPack) -> some View {
        let selected = stock.id == selectedID
        return Button {
            if locked {
                onLocked(pack)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } else {
                photo.filmStock = stock
                try? context.save()
                onChange()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } label: {
            VStack(spacing: 6) {
                LookThumbnail(
                    photoID: photo.id,
                    stock: stock,
                    rawData: rawData,
                    capturedAt: photo.capturedAt,
                    selected: selected,
                    locked: locked
                )
                Text(stock.name)
                    .font(Typography.sans(9.5, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? Palette.gold : Palette.cream.opacity(0.62))
                    .lineLimit(1)
                    .frame(width: 62)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(stock.name)\(locked ? ", locked" : "")")
        .accessibilityHint(stock.blurb)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// One live-rendered look thumbnail. Renders the print through the stock at a
/// small size via the shared LRU-cached preview renderer, so re-opening the
/// picker is instant and scrubbing looks is cheap.
private struct LookThumbnail: View {
    let photoID: UUID
    let stock: FilmStock
    let rawData: Data?
    let capturedAt: Date
    let selected: Bool
    let locked: Bool

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Palette.charcoalDeep.opacity(0.6))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }

            if locked {
                Rectangle().fill(.black.opacity(0.28))
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.cream.opacity(0.9))
                    .shadow(radius: 2)
            }
        }
        .frame(width: 62, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    selected ? Palette.gold : Palette.cream.opacity(0.14),
                    lineWidth: selected ? 2 : 1
                )
        )
        .saturation(locked ? 0.85 : 1)
        // The photo data arrives a beat after the first render, so the id has
        // to change when it lands - keyed on photo and stock alone, the task
        // ran once against a nil `rawData` and every tile stayed empty.
        .task(id: "\(photoID)|\(stock.id)|\(rawData?.count ?? 0)") {
            guard let rawData else { return }
            image = FilmPreviewRenderer.shared.preview(
                photoID: photoID,
                stock: stock,
                source: rawData,
                capturedAt: capturedAt,
                maxDimension: 160
            )
        }
    }
}
