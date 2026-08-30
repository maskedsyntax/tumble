import Foundation
import StoreKit
import Observation

public enum PurchaseOutcome: String, Sendable, CaseIterable {
    case completed
    case cancelled
    case pending
    case unverified
    case error
}

public enum RestoreOutcome: String, Sendable, CaseIterable {
    case completed
    case error
}

/// StoreKit 2, one-time purchases only. Loads the Plus and Unlimited products,
/// tracks owned entitlements, and resolves the highest tier - which then drives
/// the daily Roll. No subscriptions, ever.
@MainActor
@Observable
public final class PurchaseManager {
    public private(set) var products: [Product] = []
    public private(set) var ownedProductIDs: Set<String> = []
    public private(set) var isLoading = false

    /// The best tier the shooter owns.
    public var entitlement: Entitlement {
        Entitlement.highest(fromProductIDs: ownedProductIDs)
    }

    /// Tier products (daily Roll) plus the one-time film-pack unlocks. Packs are
    /// separate buys - they never change the Roll tier - so they load here but
    /// resolve their ownership through `ownsPack`, not `entitlement`.
    @ObservationIgnored private let tierProductIDs = ["com.tumble.plus", "com.tumble.unlimited"]
    @ObservationIgnored private lazy var productIDs: [String] =
        tierProductIDs + FilmStockCatalog.allProductIDs
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    public init() {}

    /// Begin listening for transactions and load current state.
    public func start() async {
        if updatesTask == nil { updatesTask = observeTransactionUpdates() }
        await loadProducts()
        await refreshEntitlements()
    }

    public func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        let loaded = (try? await Product.products(for: productIDs)) ?? []
        products = loaded.sorted { $0.price < $1.price }
    }

    /// The StoreKit product for a paid tier, if loaded.
    public func product(for tier: Entitlement) -> Product? {
        guard let id = tier.productID else { return nil }
        return products.first { $0.id == id }
    }

    /// The StoreKit product backing a paid film pack, if loaded.
    public func product(for pack: FilmPack) -> Product? {
        guard let id = pack.productID else { return nil }
        return products.first { $0.id == id }
    }

    /// Whether the shooter can use a pack. The free pack is always unlocked;
    /// paid packs unlock either on their own purchase or through the all-packs
    /// bundle.
    public func ownsPack(_ packID: String) -> Bool {
        guard let pack = FilmStockCatalog.pack(for: packID) else { return false }
        guard pack.productID != nil else { return true }
        return FilmStockCatalog.unlockProductIDs(for: packID).contains(where: ownedProductIDs.contains)
    }

    /// Whether every paid pack is unlocked - the bundle's job, but also true
    /// once the packs have been bought one by one.
    public var ownsEveryPack: Bool {
        FilmStockCatalog.packs.allSatisfy { ownsPack($0.id) }
    }

    /// The StoreKit product for the all-packs bundle, if loaded.
    public var bundleProduct: Product? {
        products.first { $0.id == FilmStockCatalog.bundleProductID }
    }

    /// Whether a stock is available to apply, i.e. its pack is owned.
    public func isUnlocked(_ stock: FilmStock) -> Bool {
        ownsPack(stock.packID)
    }

    @discardableResult
    public func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .unverified }
                await transaction.finish()
                await refreshEntitlements()
                return .completed
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .error
            }
        } catch {
            return .error
        }
    }

    /// Restore prior purchases (App Store sync). One-time buys are recoverable
    /// on any of the shooter's devices.
    public func restore() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return .completed
        } catch {
            return .error
        }
    }

    public func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                owned.insert(transaction.productID)
            }
        }
        ownedProductIDs = owned
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }
}
