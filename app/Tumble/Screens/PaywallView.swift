import SwiftUI
import StoreKit
import TumbleKit

/// "Pay once. Never again." Mirrors the site's Pricing cards — Free, Plus (most
/// popular), Unlimited — as one-time unlocks. Never interruptive: reached only
/// from the empty-roll state and Settings. Language stays "own more", not
/// "upgrade".
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app
    @State private var busy: String?

    private var owned: Entitlement { app.purchases.entitlement }

    var body: some View {
        ZStack {
            GraincoreBackground()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    ForEach([Entitlement.free, .plus, .unlimited], id: \.self) { tier in
                        TierCard(
                            tier: tier,
                            product: app.purchases.product(for: tier),
                            owned: owned,
                            busy: busy == tier.productID,
                            buy: { await buy(tier) }
                        )
                    }
                    Button("Restore purchases") { Task { await app.purchases.restore(); app.syncEntitlement() } }
                        .font(Typography.sans(14, weight: .semibold))
                        .foregroundStyle(Palette.cream.opacity(0.8))
                    Text("One-time purchases · no subscriptions · restore anytime")
                        .font(Typography.sans(11))
                        .foregroundStyle(Palette.cream.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .padding(.top, 30)
            }
            closeButton
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Pay once. Never again.").kicker()
            Text("Free to start.\nYours to keep.")
                .font(Typography.display(30))
                .foregroundStyle(Palette.cream)
                .multilineTextAlignment(.center)
            Text("Want more than twelve a day? Unlock it once. No subscriptions, no renewals, ever.")
                .font(Typography.sans(14))
                .foregroundStyle(Palette.cream.opacity(0.72))
                .multilineTextAlignment(.center)
        }
    }

    private func buy(_ tier: Entitlement) async {
        guard let product = app.purchases.product(for: tier) else { return }
        busy = tier.productID
        defer { busy = nil }
        if await app.purchases.purchase(product) {
            app.syncEntitlement()
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
                        .padding(10).background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 6)
    }
}

private struct TierCard: View {
    let tier: Entitlement
    let product: Product?
    let owned: Entitlement
    let busy: Bool
    let buy: () async -> Void

    private var isOwned: Bool { owned >= tier && tier != .free }
    private var featured: Bool { tier == .plus }

    private var shotsLabel: String {
        switch tier {
        case .free: "12 shots a day"
        case .plus: "72 shots a day"
        case .unlimited: "Unlimited shots"
        }
    }

    private var blurb: String {
        switch tier {
        case .free: "The daily roll, shake-to-develop, and the whole Drawer."
        case .plus: "Six rolls a day for heavier shooters, still fresh every morning."
        case .unlimited: "No daily limit at all. Shoot as much as you like."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if featured {
                Text("Most popular")
                    .font(Typography.sans(11, weight: .semibold))
                    .tracking(1).textCase(.uppercase)
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Palette.gold, in: Capsule())
            }
            Text(tier.rawValue.capitalized)
                .font(Typography.sans(13, weight: .semibold))
                .tracking(1.5).textCase(.uppercase)
                .foregroundStyle(Palette.cream.opacity(0.6))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(product?.displayPrice ?? tier.priceLabel)
                    .font(Typography.display(34))
                    .foregroundStyle(Palette.cream)
                if tier != .free {
                    Text("one-time").font(Typography.sans(13)).foregroundStyle(Palette.cream.opacity(0.5))
                }
            }

            Text(shotsLabel).font(Typography.sans(15, weight: .medium)).foregroundStyle(Palette.gold)
            Text(blurb).font(Typography.sans(13)).foregroundStyle(Palette.cream.opacity(0.7))

            action.padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(featured ? Palette.gold.opacity(0.08) : Palette.cream.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(featured ? Palette.gold.opacity(0.5) : Palette.cream.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder private var action: some View {
        if tier == .free {
            Text(owned == .free ? "Your current roll" : "Included")
                .font(Typography.sans(13, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.5))
        } else if isOwned {
            Label("Owned", systemImage: "checkmark.seal.fill")
                .font(Typography.sans(14, weight: .semibold))
                .foregroundStyle(Palette.gold)
        } else {
            Button { Task { await buy() } } label: {
                HStack {
                    if busy { ProgressView().tint(Palette.ink) }
                    Text(busy ? "" : "Own it")
                        .font(Typography.sans(15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(busy || product == nil)
            .opacity(product == nil ? 0.5 : 1)
        }
    }
}
