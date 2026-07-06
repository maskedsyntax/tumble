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
        for (i, scene) in scenes.enumerated() {
            let photo = Photo(source: .app)
            photo.capturedAt = Date().addingTimeInterval(-Double(i) * 60 * 60 * 24 * 5) // spread ages
            let img = scene.image()
            if let data = img.jpegData(compressionQuality: 0.9) {
                photo.rawImageName = try? PhotoStore.writeImage(data, id: photo.id, kind: .raw)
            }
            // Leave the two newest undeveloped so the develop flow is visible.
            photo.isDeveloped = i >= 2
            photo.developProgress = i >= 2 ? 1 : 0
            context.insert(photo)
        }
        try? context.save()
    }
}
