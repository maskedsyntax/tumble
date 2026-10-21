import Foundation
import SwiftData
import TumbleKit

/// Keeps every finished edit in the Drawer: the finished JPEG to look at and
/// share again, and the source plus recipe so it can be reopened in Studio.
enum DrawerArchive {
    /// Files the draft's finished image. Saving and sharing the same draft
    /// update one print rather than stacking copies.
    @MainActor
    static func keep(
        draft: EditDraft,
        recipe: EditRecipe,
        source: Data,
        finished: Data,
        in context: ModelContext
    ) async {
        let id = draft.id
        let existing = try? context.fetch(FetchDescriptor<Photo>(predicate: #Predicate { $0.id == id })).first
        let photo = existing ?? Photo(id: id, source: .app)
        do {
            if photo.rawImageName == nil {
                photo.rawImageName = try await PhotoStore.writeImageAsync(source, id: id, kind: .raw)
            }
            photo.developedImageName = try await PhotoStore.writeImageAsync(finished, id: id, kind: .developed)
        } catch {
            if existing == nil { PhotoStore.deleteImages(for: photo) }
            return
        }
        if existing != nil {
            // The finished file keeps its name, so drop thumbnails of the old one.
            await PhotoThumbnailRepository.shared.removeAll()
        }
        photo.capturedAt = Date()
        photo.isDeveloped = true
        photo.developProgress = 1
        photo.filterID = recipe.stockID
        photo.frameStyle = recipe.frameStyle
        photo.edit = PrintEdit(recipe: recipe, sourceKind: draft.sourceKind, capturedAt: draft.capturedAt)
        if existing == nil { context.insert(photo) }
        try? context.save()
    }
}
