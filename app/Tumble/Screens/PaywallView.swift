import SwiftUI
import StoreKit
import TumbleKit

/// "Pay once. Never again." - the app's single Store & About screen. Shows the
/// three one-time tiers (Free · Plus · Unlimited), Restore, and the on-device
/// promise. Reached from the header, the low-roll nudge, and the empty roll.
/// Language stays "own more", not "upgrade".
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app
    @State private var busy: String?
    @State private var appeared = false

    private var owned: Entitlement { app.purchases.entitlement }
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            GraincoreBackground()

            ScrollView {
                VStack(spacing: 20) {
                    hero
                    header
                    VStack(spacing: 14) {
                        ForEach([Entitlement.plus, .unlimited, .free], id: \.self) { tier in
                            TierCard(
                                tier: tier,
                                product: app.purchases.product(for: tier),
                                owned: owned,
                                busy: busy == tier.productID,
                                buy: { await buy(tier) }
                            )
                        }
                    }
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 52)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }

            closeButton
        }
        .task {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    // MARK: Hero - a little fan of prints, echoing the Drawer.

    private var hero: some View {
        ZStack {
            HeroPrint(scene: .blueHourRooftop, rotation: -13, offset: CGSize(width: -64, height: 10))
            HeroPrint(scene: .sunlitPark, rotation: 9, offset: CGSize(width: 60, height: 6))
            HeroPrint(scene: .goldenHour, rotation: -2, offset: CGSize(width: 0, height: -6))
        }
        .frame(height: 150)
        .shadow(color: Palette.gold.opacity(0.18), radius: 26, y: 14)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Pay once. Never again.").kicker()
            Text("Free to start.\nYours to keep.")
                .font(Typography.display(32))
                .foregroundStyle(Palette.cream)
                .multilineTextAlignment(.center)
            Text("Want more than twelve a day? Unlock it once - no subscriptions, no renewals, ever.")
                .font(Typography.sans(14))
                .foregroundStyle(Palette.cream.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: Footer - restore + the on-device promise (folded in from Settings).

    private var footer: some View {
        VStack(spacing: 16) {
            Button { Task { await app.purchases.restore(); app.syncEntitlement() } } label: {
                Text("Restore purchases")
                    .font(Typography.sans(14, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.85))
                    .padding(.horizontal, 18).padding(.vertical, 9)
                    .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.22)))
            }
            .buttonStyle(.plain)

            HStack(spacing: 14) {
                promiseItem("iphone", "On-device")
                promiseItem("person.crop.circle.badge.xmark", "No account")
                promiseItem("icloud.slash", "No cloud")
            }
            .padding(.top, 2)

            Text("One-time purchases · no subscriptions · restore anytime")
                .font(Typography.sans(11))
                .foregroundStyle(Palette.cream.opacity(0.45))
                .multilineTextAlignment(.center)
            Text("Version \(version) · Made for shooting, not scrolling.")
                .font(Typography.sans(11))
                .foregroundStyle(Palette.cream.opacity(0.35))
        }
        .padding(.top, 6)
    }

    private func promiseItem(_ icon: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Palette.amber.opacity(0.9))
            Text(label)
                .font(Typography.sans(11, weight: .medium))
                .foregroundStyle(Palette.cream.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
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
                        .padding(10).background(.black.opacity(0.3), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 6)
    }
}

// MARK: - Hero print

private struct HeroPrint: View {
    let scene: FilmScene
    let rotation: Double
    let offset: CGSize
    @State private var image: UIImage?

    var body: some View {
        PrintView(image: image, isDeveloped: true, developProgress: 1, age: 0.15, width: 116)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .task { image = scene.image(size: 400) }
    }
}

// MARK: - Tier card

private struct TierCard: View {
    let tier: Entitlement
    let product: Product?
    let owned: Entitlement
    let busy: Bool
    let buy: () async -> Void

    private var isOwned: Bool { owned >= tier && tier != .free }
    private var featured: Bool { tier == .plus }
    private var isCurrentFree: Bool { tier == .free && owned == .free }

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
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(tier.rawValue.capitalized)
                    .font(Typography.sans(12, weight: .semibold))
                    .tracking(1.6).textCase(.uppercase)
                    .foregroundStyle(featured ? Palette.gold : Palette.cream.opacity(0.6))
                Spacer()
                if featured {
                    Text("Most popular")
                        .font(Typography.sans(10, weight: .bold))
                        .tracking(0.8).textCase(.uppercase)
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Palette.gold, in: Capsule())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(product?.displayPrice ?? tier.priceLabel)
                    .font(Typography.display(featured ? 40 : 32))
                    .foregroundStyle(Palette.cream)
                if tier != .free {
                    Text("one-time").font(Typography.sans(13)).foregroundStyle(Palette.cream.opacity(0.5))
                }
            }

            Text(shotsLabel).font(Typography.sans(15, weight: .semibold)).foregroundStyle(Palette.gold)
            Text(blurb).font(Typography.sans(13)).foregroundStyle(Palette.cream.opacity(0.72))

            action.padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(featured ? 22 : 18)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: featured ? Palette.gold.opacity(0.22) : .black.opacity(0.15),
                radius: featured ? 22 : 10, y: featured ? 12 : 6)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                featured
                    ? LinearGradient(colors: [Palette.gold.opacity(0.16), Palette.gold.opacity(0.05)],
                                     startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Palette.cream.opacity(0.05), Palette.cream.opacity(0.03)],
                                     startPoint: .top, endPoint: .bottom)
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(featured ? Palette.gold.opacity(0.55) : Palette.cream.opacity(0.14),
                          lineWidth: featured ? 1.5 : 1)
    }

    @ViewBuilder private var action: some View {
        if tier == .free {
            Text(isCurrentFree ? "Your current roll" : "Included")
                .font(Typography.sans(13, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.5))
        } else if isOwned {
            Label("Owned", systemImage: "checkmark.seal.fill")
                .font(Typography.sans(14, weight: .semibold))
                .foregroundStyle(Palette.gold)
        } else {
            Button { Task { await buy() } } label: {
                ZStack {
                    if busy { ProgressView().tint(Palette.ink) }
                    Text(busy ? "" : "Own it")
                        .font(Typography.sans(15, weight: .bold))
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Palette.gold, in: Capsule())
                .shadow(color: Palette.gold.opacity(featured ? 0.3 : 0), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(busy || product == nil)
            .opacity(product == nil ? 0.5 : 1)
        }
    }
}
