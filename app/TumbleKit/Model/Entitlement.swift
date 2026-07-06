import Foundation

/// What the shooter owns. One-time purchases only — no subscriptions, per the
/// product's whole stance. Ordered so the highest owned tier wins.
public enum Entitlement: String, Sendable, CaseIterable, Comparable {
    case free
    case plus
    case unlimited

    /// Shots granted each morning. `nil` means no daily limit (Unlimited).
    public var dailyQuota: Int? {
        switch self {
        case .free: 12
        case .plus: 72
        case .unlimited: nil
        }
    }

    /// Display price mirroring the site's Pricing cards.
    public var priceLabel: String {
        switch self {
        case .free: "Free"
        case .plus: "$5.99"
        case .unlimited: "$11.99"
        }
    }

    /// The StoreKit product id for the paid tiers.
    public var productID: String? {
        switch self {
        case .free: nil
        case .plus: "com.tumble.plus"
        case .unlimited: "com.tumble.unlimited"
        }
    }

    private var rank: Int {
        switch self {
        case .free: 0
        case .plus: 1
        case .unlimited: 2
        }
    }

    public static func < (lhs: Entitlement, rhs: Entitlement) -> Bool {
        lhs.rank < rhs.rank
    }

    /// Resolve the highest tier from a set of owned product ids.
    public static func highest(fromProductIDs ids: Set<String>) -> Entitlement {
        var best = Entitlement.free
        for tier in allCases where tier.productID.map(ids.contains) == true {
            best = max(best, tier)
        }
        return best
    }
}
