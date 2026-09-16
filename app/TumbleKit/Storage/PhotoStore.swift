import Foundation
import ImageIO
import SwiftData
import UIKit

/// Owns the on-device SwiftData store (kept in the shared App Group container)
/// and the image files that back each `Photo`. No photo cloud - this is
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

    public static func writeImageAsync(_ data: Data, id: UUID, kind: ImageKind) async throws -> String {
        try await Task.detached(priority: .utility) {
            try writeImage(data, id: id, kind: kind)
        }.value
    }

    public static func loadImageData(named name: String?) -> Data? {
        guard let name else { return nil }
        return try? Data(contentsOf: imageURL(named: name))
    }

    public static func loadImageDataAsync(named name: String?) async -> Data? {
        guard let name else { return nil }
        let url = imageURL(named: name)
        return await Task.detached(priority: .utility) {
            try? Data(contentsOf: url, options: [.mappedIfSafe])
        }.value
    }

    public static func deleteImage(named name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: imageURL(named: name))
    }

    public static func deleteImages(for photo: Photo) {
        deleteImage(named: photo.rawImageName)
        deleteImage(named: photo.developedImageName)
    }

    public enum ImageKind: Sendable {
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

/// Off-main, size-aware image loading shared by every grid and pile. NSCache is
/// thread-safe and automatically sheds decoded images under memory pressure.
public actor PhotoThumbnailRepository {
    public static let shared = PhotoThumbnailRepository()

    private let cache = NSCache<NSString, UIImage>()

    public init(countLimit: Int = 96) {
        cache.countLimit = countLimit
        cache.totalCostLimit = 96 * 1_024 * 1_024
    }

    public func image(named name: String?, maxPixelSize: Int) -> UIImage? {
        guard let name, !Task.isCancelled else { return nil }
        return image(
            at: PhotoStore.imageURL(named: name),
            cacheKey: name,
            maxPixelSize: maxPixelSize
        )
    }

    func image(at url: URL, cacheKey: String, maxPixelSize: Int) -> UIImage? {
        guard !Task.isCancelled else { return nil }
        let size = max(32, maxPixelSize)
        let key = "\(cacheKey)|\(size)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: size,
                kCGImageSourceShouldCacheImmediately: true,
              ] as CFDictionary) else { return nil }

        guard !Task.isCancelled else { return nil }
        let image = UIImage(cgImage: cgImage)
        cache.setObject(image, forKey: key, cost: cgImage.bytesPerRow * cgImage.height)
        return image
    }

    public func removeAll() {
        cache.removeAllObjects()
    }
}
