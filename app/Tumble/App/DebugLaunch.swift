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

    /// `-focusNote` opens the postcard note with the keyboard already up, so
    /// the squeezed-keyboard layout can be checked from the command line.
    static var focusesNote: Bool {
        #if DEBUG
        return arguments.contains("-focusNote")
        #else
        return false
        #endif
    }

    static var showsOriginal: Bool {
        #if DEBUG
        return arguments.contains("-showOriginal")
        #else
        return false
        #endif
    }

    static var opensPhotoPicker: Bool {
        #if DEBUG
        return arguments.contains("-photoPickerDemo")
        #else
        return false
        #endif
    }

    static var clearsDraft: Bool {
        #if DEBUG
        return arguments.contains("-clearDraft")
        #else
        return false
        #endif
    }

    static var opensSettings: Bool {
        #if DEBUG
        return arguments.contains("-settingsDemo")
        #else
        return false
        #endif
    }

    static var opensAccount: Bool {
        #if DEBUG
        return arguments.contains("-accountDemo")
        #else
        return false
        #endif
    }

    /// Lets screenshots exercise the free-user Settings presentation without
    /// touching StoreKit receipts or the signed-in RevenueCat customer.
    static var previewsFreeSettings: Bool {
        #if DEBUG
        return arguments.contains("-previewFreeSettings")
        #else
        return false
        #endif
    }

    /// Presentation-only signed-out state for reviewing the account UI. It
    /// never signs the real Firebase user out.
    static var previewsSignedOutAccount: Bool {
        #if DEBUG
        return arguments.contains("-previewSignedOutAccount")
        #else
        return false
        #endif
    }

    /// True while the app is being driven to a screen for a capture.
    static var isCapturing: Bool {
        packPaywall != nil
            || arguments.contains("-studioDemo")
            || arguments.contains("-finishDemo")
            || arguments.contains("-completeDemo")
            || arguments.contains("-cameraDemo")
            || opensPhotoPicker
            || clearsDraft
            || opensSettings
            || opensAccount
    }

    /// Loads a capture-only photograph copied into the app's Documents
    /// directory by the screenshot script. Keeping it outside the bundle
    /// means model/party photography can never leak into a Release archive.
    static var demoImageData: Data? {
        #if DEBUG
        guard let name = value(for: "-demoImage") else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return try? Data(contentsOf: documents.appendingPathComponent(name))
        #else
        return nil
        #endif
    }

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
