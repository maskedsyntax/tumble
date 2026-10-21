import SwiftUI
import SwiftData
import TumbleKit

/// Populates the Drawer with sample roll prints for Simulator UI verification.
/// Only runs when launched with the `-seed` argument; never in normal use.
enum DebugSeed {
    static var requested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seed")
    }

    @MainActor
    static func run(in context: ModelContext) {
        guard requested else { return }
        // Avoid double-seeding across relaunches. Studio prints from other
        // runs don't count; these stand in for the retired roll.
        let existing = (try? context.fetch(FetchDescriptor<Photo>()))?.filter { !$0.isStudioEdit }.count ?? 0
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

    /// Replaces the Drawer with finished Studio prints of the App Store photos
    /// copied into Documents, rendered exactly as Finish exports them. Only
    /// with `-drawerDemo`, for the store capture.
    @MainActor
    static func drawerDemo(in context: ModelContext) async {
        guard ProcessInfo.processInfo.arguments.contains("-drawerDemo") else { return }
        for photo in (try? context.fetch(FetchDescriptor<Photo>())) ?? [] {
            PhotoStore.deleteImages(for: photo)
            context.delete(photo)
        }
        try? context.save()

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let prints: [(image: String, stock: String, frame: PostcardFrameStyle, note: String, month: Int, day: Int)] = [
            ("09-beach-run", "goldenHour", .none, "", 10, 15),
            ("06-rainy-crosswalk", "warmArchive", .classicInstant, "Wish you were here", 10, 12),
            ("03-flower-market", "silver", .none, "", 10, 8),
            ("08-sidewalk-cafe", "fadedInstant", .deckledEdge, "Same table next year?", 10, 4),
            ("10-motel-pool", "hazyFlare", .none, "", 9, 25),
            ("15-concert", "crossProcess", .none, "", 9, 19),
            ("05-coastal-drive", "sunbleached", .vintagePostcard, "Coast road, July", 9, 12),
            ("13-skateboard", "everyday", .none, "", 9, 6),
        ]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        for item in prints {
            guard let source = try? Data(contentsOf: documents.appendingPathComponent(item.image + ".png")) else { continue }
            let finishedAt = calendar.date(from: DateComponents(year: 2026, month: item.month, day: item.day, hour: 18))!
            let recipe = EditRecipe(stockID: item.stock, frameID: item.frame.rawValue, note: item.note)
            let draft = EditDraft(sourceFile: item.image, sourceKind: .library, capturedAt: finishedAt, recipe: recipe)
            guard let finished = await FinishedExport.render(
                source: source,
                recipe: recipe,
                frame: item.frame,
                capturedAt: finishedAt,
                seed: draft.id.stableSeed
            ) else { continue }
            await DrawerArchive.keep(draft: draft, recipe: recipe, source: source, finished: finished, in: context)
            let id = draft.id
            if let kept = try? context.fetch(FetchDescriptor<Photo>(predicate: #Predicate { $0.id == id })).first {
                kept.capturedAt = finishedAt
                // A gentle, alternating lean rather than a random one.
                kept.rotation = [-7.0, 6, -4, 8, -6, 5, -8, 4][prints.firstIndex { $0.image == item.image } ?? 0]
            }
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
