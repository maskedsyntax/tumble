import Foundation

/// Shared container plumbing. The app and the lock-screen capture extension
/// must see the same Drawer and the same roll counter, so both point at the
/// App Group. When the group container is unavailable (e.g. an unsigned
/// simulator/unit-test build), we fall back to the app's own Application
/// Support directory so everything still works locally.
public enum AppGroup {
    public static let identifier = "group.com.tumble"

    /// Root of the shared container, or a local fallback.
    public static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? fallbackRoot
    }

    /// Shared defaults for small state like the roll counter.
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// Directory holding the raw and developed image files.
    public static var imagesURL: URL {
        let url = containerURL.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Location of the SwiftData store.
    public static var storeURL: URL {
        containerURL.appendingPathComponent("Tumble.store")
    }

    private static var fallbackRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base.appendingPathComponent("Tumble", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
