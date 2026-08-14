import Foundation
import TumbleKit

/// Launch arguments that drive the app straight to a screen, so screenshots can
/// be captured from the command line instead of tapped out by hand. Debug only -
/// none of this exists in a release build.
enum DebugLaunch {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static func value(for flag: String) -> String? {
        #if DEBUG
        guard let i = arguments.firstIndex(of: flag), i + 1 < arguments.count else { return nil }
        let next = arguments[i + 1]
        return next.hasPrefix("-") ? nil : next
        #else
        return nil
        #endif
    }

    /// `-packPaywall <packID>` opens that pack's store card over the Drawer.
    static var packPaywall: FilmPack? {
        guard let id = value(for: "-packPaywall") else { return nil }
        return FilmStockCatalog.pack(for: id)
    }

    /// True while the app is being driven to a screen for a capture.
    static var isCapturing: Bool { packPaywall != nil }

    /// Prices to draw when StoreKit has no products to offer - which is the
    /// case for any launch outside Xcode, since the `.storekit` configuration
    /// is attached to the run scheme. Screenshot scaffolding only: a real
    /// launch always prefers `Product.displayPrice`, which is localised.
    ///
    /// Keep in step with `app/Tumble.storekit`.
    static func placeholderPrice(for productID: String?) -> String? {
        #if DEBUG
        guard isCapturing, let productID else { return nil }
        return productID == FilmStockCatalog.bundleProductID ? "$4.99" : "$1.99"
        #else
        return nil
        #endif
    }
}
