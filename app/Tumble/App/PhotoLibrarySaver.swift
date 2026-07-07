import Photos
import TumbleKit

enum PhotoLibrarySaveResult: Equatable {
    case saved(Int)
    case noDevelopedPhotos
    case denied
    case failed
}

/// Writes developed prints to the user's Photos library only when they ask.
enum PhotoLibrarySaver {
    @MainActor
    static func saveDeveloped(_ photo: Photo) async -> PhotoLibrarySaveResult {
        guard photo.isDeveloped, let data = imageData(for: photo) else {
            return .noDevelopedPhotos
        }

        return await save([data])
    }

    @MainActor
    static func saveDeveloped(in photos: [Photo]) async -> PhotoLibrarySaveResult {
        let imagesData = photos
            .filter(\.isDeveloped)
            .compactMap(imageData(for:))

        guard !imagesData.isEmpty else {
            return .noDevelopedPhotos
        }

        return await save(imagesData)
    }

    @MainActor
    private static func imageData(for photo: Photo) -> Data? {
        let name = photo.developedImageName ?? photo.rawImageName
        return PhotoStore.loadImageData(named: name)
    }

    private static func save(_ imagesData: [Data]) async -> PhotoLibrarySaveResult {
        guard await canAddToLibrary() else {
            return .denied
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                for data in imagesData {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }
            } completionHandler: { success, _ in
                continuation.resume(returning: success ? .saved(imagesData.count) : .failed)
            }
        }
    }

    private static func canAddToLibrary() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    continuation.resume(returning: status)
                }
            }
            return status == .authorized || status == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
