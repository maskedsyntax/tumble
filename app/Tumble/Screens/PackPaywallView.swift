import SwiftUI
import StoreKit
import TumbleKit

/// The film-pack store card. Reached by tapping a locked look: it shows the
/// pack's stocks rendered over a sample scene, the one-time price, and an Own it
/// button. Same "pay once, keep forever" stance as the tier paywall - packs are
/// content, never a subscription.
struct PackPaywallView: View {
    let pack: FilmPack

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var sampleData: Data?

    private var stocks: [FilmStock] { FilmStockCatalog.stocks(in: pack.id) }
    private var product: Product? { app.purchases.product(for: pack) }
    private var owned: Bool { app.purchases.ownsPack(pack.id) }

    /// The all-packs bundle, offered under the single pack - but only while
    /// there is still something left to bundle.
    private var bundle: Product? {
        app.purchases.ownsEveryPack ? nil : app.purchases.bundleProduct
    }
    private var bundleStockCount: Int {
        FilmStockCatalog.packs.filter { !$0.isFree }.reduce(0) { $0 + FilmStockCatalog.stocks(in: $1.id).count }
    }

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 140), spacing: 12)]

    var body: some View {
        ZStack {
            GraincoreBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(stocks) { stock in
                            SampleTile(stock: stock, sampleData: sampleData)
                        }
                    }

                    action
                    bundleOffer
                    restore
                }
                .padding(.horizontal, 22)
                .padding(.top, 52)
                .padding(.bottom, 40)
            }

            closeButton
        }
        .task {
            // One shared sample scene, rendered through each stock, so the tiles
            // differ only by the look.
            sampleData = FilmScene.goldenHour.image(size: 640).jpegData(compressionQuality: 0.9)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Film Pack").kicker()
            Text(pack.name)
                .font(Typography.display(32))
                .foregroundStyle(Palette.cream)
                .multilineTextAlignment(.center)
            Text(pack.blurb)
                .font(Typography.sans(14))
                .foregroundStyle(Palette.cream.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Text("\(stocks.count) looks · one-time unlock")
                .font(Typography.sans(12, weight: .semibold))
                .foregroundStyle(Palette.gold)
        }
    }

    @ViewBuilder private var action: some View {
        if owned {
            Label("Owned", systemImage: "checkmark.seal.fill")
                .font(Typography.sans(15, weight: .semibold))
                .foregroundStyle(Palette.gold)
                .padding(.top, 4)
        } else {
            Button { Task { await buy() } } label: {
                ZStack {
                    if busy { ProgressView().tint(Palette.ink) }
                    Text(busy ? "" : "Own it · \(product?.displayPrice ?? "…")")
                        .font(Typography.sans(15, weight: .bold))
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Palette.gold, in: Capsule())
                .shadow(color: Palette.gold.opacity(0.28), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(busy || product == nil)
            .opacity(product == nil ? 0.5 : 1)
            .padding(.top, 4)
        }
    }

    /// The upsell: every pack for less than the sum of its parts. Shown under
    /// the single-pack button so it reads as an upgrade, not a competing offer.
    @ViewBuilder private var bundleOffer: some View {
        if let bundle {
            Button { Task { await buy(bundle) } } label: {
                VStack(spacing: 3) {
                    Text("Or take every pack · \(bundle.displayPrice)")
                        .font(Typography.sans(14, weight: .bold))
                        .foregroundStyle(Palette.cream)
                    Text("\(bundleStockCount) looks, one payment")
                        .font(Typography.sans(12))
                        .foregroundStyle(Palette.cream.opacity(0.65))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Palette.gold.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(busy)
        }
    }

    private var restore: some View {
        Button { Task { await app.purchases.restore() } } label: {
            Text("Restore purchases")
                .font(Typography.sans(13, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.75))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }

    private func buy(_ product: Product? = nil) async {
        guard let product = product ?? self.product else { return }
        busy = true
        defer { busy = false }
        if await app.purchases.purchase(product), owned {
            dismiss()
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
                        .padding(10).background(.black.opacity(0.3), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 6)
    }
}

/// A sample scene rendered through one stock, labelled with the stock's name -
/// so a shopper sees exactly what each look does before buying the pack.
private struct SampleTile: View {
    let stock: FilmStock
    let sampleData: Data?
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Palette.charcoalDeep.opacity(0.6))
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Palette.cream.opacity(0.14), lineWidth: 1)
            )

            Text(stock.name)
                .font(Typography.sans(11, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.8))
                .lineLimit(1)
        }
        .task(id: "\(stock.id)|\(sampleData?.count ?? 0)") {
            guard let sampleData else { return }
            image = TumblePhotoFilter.renderPreviewImage(
                from: sampleData,
                grade: stock.grade,
                capturedAt: Date(),
                maxDimension: 220
            )
        }
    }
}
