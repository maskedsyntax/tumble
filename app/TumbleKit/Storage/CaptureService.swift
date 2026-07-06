import SwiftUI
import SwiftData

/// Turns a captured frame into a stored, undeveloped print — spending a shot,
/// writing the raw bytes, and inserting the `Photo`. Shared by the app and the
/// lock-screen capture extension so both enforce the same Roll and write to the
/// same Drawer.
public enum CaptureService {
    @MainActor
    @discardableResult
    public static func store(
        rawImage: UIImage,
        source: PhotoSource,
        roll: RollManager,
        in context: ModelContext
    ) -> Photo? {
        guard roll.consumeShot() else { return nil }

        let photo = Photo(source: source)
        if let data = rawImage.jpegData(compressionQuality: 0.9) {
            photo.rawImageName = try? PhotoStore.writeImage(data, id: photo.id, kind: .raw)
        }
        context.insert(photo)
        try? context.save()
        return photo
    }
}
