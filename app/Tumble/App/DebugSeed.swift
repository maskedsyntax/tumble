import SwiftUI
import SwiftData
import TumbleKit

/// Populates the Drawer with sample prints for Simulator UI verification.
/// Only runs when launched with the `-seed` argument; never in normal use.
enum DebugSeed {
    static var requested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seed")
    }

    @MainActor
    static func run(in context: ModelContext) {
        guard requested else { return }
        // Avoid double-seeding across relaunches.
        let existing = (try? context.fetch(FetchDescriptor<Photo>()))?.count ?? 0
        guard existing == 0 else { return }

        let scenes = FilmScene.allCases
        for i in 0..<count {
            let scene = scenes[i % scenes.count]
            let photo = Photo(source: .app)
            photo.capturedAt = Date().addingTimeInterval(-Double(i) * 60 * 60 * 24 * 5) // spread ages
            let img = scene.image()
            if let data = img.jpegData(compressionQuality: 0.9) {
                photo.rawImageName = try? PhotoStore.writeImage(data, id: photo.id, kind: .raw)
            }
            // Leave the newest undeveloped so the develop flow is visible.
            photo.isDeveloped = i >= min(2, count - 1)
            photo.developProgress = photo.isDeveloped ? 1 : 0
            if photo.isDeveloped,
               let rawData = PhotoStore.loadImageData(named: photo.rawImageName),
               let memoryData = TumblePhotoFilter.renderMemoryPhotoData(from: rawData, preset: TumbleMemoryFilterPreset.defaultPreset) {
                photo.developedImageName = try? PhotoStore.writeImage(memoryData, id: photo.id, kind: .developed)
            }
            context.insert(photo)
        }
        try? context.save()
    }

    /// Number of prints to seed - pass `-count N`; defaults to all scenes.
    private static var count: Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-count"), i + 1 < args.count, let n = Int(args[i + 1]) {
            return max(1, n)
        }
        return FilmScene.allCases.count
    }
}
