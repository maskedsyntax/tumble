import Foundation
import StoreKit
import Observation

/// StoreKit 2, one-time purchases only. Loads the Plus and Unlimited products,
/// tracks owned entitlements, and resolves the highest tier — which then drives
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

    @ObservationIgnored private let productIDs = ["com.tumble.plus", "com.tumble.unlimited"]
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

    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        guard let result = try? await product.purchase() else { return false }
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Restore prior purchases (App Store sync). One-time buys are recoverable
    /// on any of the shooter's devices.
    public func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
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
