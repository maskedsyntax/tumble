import Photos
import SwiftUI
import TumbleKit

enum PhotoLibrarySaveResult: Equatable {
    case saved(Int)
    case noDevelopedPhotos
    case denied
    case failed
}

enum PhotoLibrarySaveStyle {
    case photoOnly
    case postcardFrame
}

/// Writes developed prints to the user's Photos library only when they ask.
enum PhotoLibrarySaver {
    @MainActor
    static func saveDeveloped(_ photo: Photo, style: PhotoLibrarySaveStyle) async -> PhotoLibrarySaveResult {
        guard photo.isDeveloped, let data = imageData(for: photo, style: style) else {
            return .noDevelopedPhotos
        }

        return await save([data])
    }

    @MainActor
    static func saveDeveloped(in photos: [Photo], style: PhotoLibrarySaveStyle) async -> PhotoLibrarySaveResult {
        let imagesData = photos
            .filter(\.isDeveloped)
            .compactMap { imageData(for: $0, style: style) }

        guard !imagesData.isEmpty else {
            return .noDevelopedPhotos
        }

        return await save(imagesData)
    }

    @MainActor
    private static func imageData(for photo: Photo, style: PhotoLibrarySaveStyle) -> Data? {
        guard let data = memoryPhotoData(for: photo) else { return nil }
        guard style == .postcardFrame else { return data }
        guard let image = UIImage(data: data) else { return nil }
        return postcardFrameData(for: photo, image: image)
    }

    @MainActor
    private static func memoryPhotoData(for photo: Photo) -> Data? {
        let preset = TumbleMemoryFilterPreset.stored()
        if let rawData = PhotoStore.loadImageData(named: photo.rawImageName),
           let memoryData = TumblePhotoFilter.renderMemoryPhotoData(from: rawData, preset: preset) {
            return memoryData
        }
        return PhotoStore.loadImageData(named: photo.developedImageName ?? photo.rawImageName)
    }

    @MainActor
    private static func postcardFrameData(for photo: Photo, image: UIImage) -> Data? {
        let content = PrintView(
            image: image,
            isDeveloped: true,
            developProgress: 1,
            age: photo.ageFraction(),
            caption: photo.caption,
            width: 1280
        )
        .padding(90)
        .background(Color.white)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        return renderer.uiImage?.jpegData(compressionQuality: 0.92)
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
