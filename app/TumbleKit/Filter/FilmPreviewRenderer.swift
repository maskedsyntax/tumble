import Foundation
import UIKit

/// A small fixed-capacity cache that evicts the least-recently-used entry once
/// it fills. Backed by a dictionary for lookup and an array for recency order;
/// the array stays short (a screenful of thumbnails), so the linear touch cost
/// is nothing. Not thread-safe - the preview renderer holds it on the main actor.
final class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var store: [Key: Value] = [:]
    /// Most-recently-used last.
    private var order: [Key] = []

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    func value(for key: Key) -> Value? {
        guard let value = store[key] else { return nil }
        touch(key)
        return value
    }

    func set(_ value: Value, for key: Key) {
        store[key] = value
        touch(key)
        while order.count > capacity, let oldest = order.first {
            order.removeFirst()
            store[oldest] = nil
        }
    }

    func removeAll() {
        store.removeAll()
        order.removeAll()
    }

    private func touch(_ key: Key) {
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
        }
        order.append(key)
    }
}

/// Renders and caches downscaled look previews for the picker. A miss runs the
/// grade pipeline once and keeps the result; a hit is a dictionary lookup. The
/// key folds in the preview size, so the same photo cached small and large never
/// collide.
@MainActor public final class FilmPreviewRenderer {
    public static let shared = FilmPreviewRenderer()

    private struct Key: Hashable {
        let photoID: UUID
        let stockID: String
        let side: Int
    }

    private let cache: LRUCache<Key, UIImage>

    public init(capacity: Int = 60) {
        cache = LRUCache(capacity: capacity)

        // Previews are cheap to rebuild and the source images can be large, so
        // drop everything the moment the system asks for memory back.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.cache.removeAll() }
        }
    }

    /// A cached preview of `photoID` under `stock`. On a miss, `source` is read
    /// (only then - it is an autoclosure) and the pipeline runs at `maxDimension`.
    public func preview(
        photoID: UUID,
        stock: FilmStock,
        source: @autoclosure () -> Data?,
        capturedAt: Date? = nil,
        maxDimension: CGFloat = 320
    ) -> UIImage? {
        let key = Key(photoID: photoID, stockID: stock.id, side: Int(maxDimension.rounded()))
        if let hit = cache.value(for: key) {
            return hit
        }
        guard let data = source() else { return nil }
        guard let image = TumblePhotoFilter.renderPreviewImage(
            from: data,
            grade: stock.grade,
            capturedAt: capturedAt,
            maxDimension: maxDimension
        ) else {
            return nil
        }
        cache.set(image, for: key)
        return image
    }

    /// Forget one photo's previews - call after its pixels change on disk so a
    /// stale thumbnail can't linger.
    public func invalidate(photoID: UUID) {
        // Cheap and rare; rebuild the whole cache without the gone photo would
        // need key enumeration, so just clear it.
        cache.removeAll()
    }

    public func clear() {
        cache.removeAll()
    }
}
