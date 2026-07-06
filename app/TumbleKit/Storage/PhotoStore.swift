import Foundation
import SwiftData

/// Owns the on-device SwiftData store (kept in the shared App Group container)
/// and the image files that back each `Photo`. No cloud, no account — this is
/// the entire persistence layer.
public enum PhotoStore {
    /// Build the SwiftData container. `inMemory` is used by unit tests.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let config = inMemory
            ? ModelConfiguration(isStoredInMemoryOnly: true)
            : ModelConfiguration(url: AppGroup.storeURL)
        return try ModelContainer(for: Photo.self, configurations: config)
    }

    // MARK: Image files

    public static func imageURL(named name: String) -> URL {
        AppGroup.imagesURL.appendingPathComponent(name)
    }

    /// Persist image bytes and return the file name to store on the `Photo`.
    @discardableResult
    public static func writeImage(_ data: Data, id: UUID, kind: ImageKind) throws -> String {
        let name = "\(id.uuidString)-\(kind.suffix).jpg"
        try data.write(to: imageURL(named: name), options: .atomic)
        return name
    }

    public static func loadImageData(named name: String?) -> Data? {
        guard let name else { return nil }
        return try? Data(contentsOf: imageURL(named: name))
    }

    public static func deleteImage(named name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: imageURL(named: name))
    }

    public enum ImageKind {
        case raw
        case developed

        var suffix: String {
            switch self {
            case .raw: "raw"
            case .developed: "dev"
            }
        }
    }
}
