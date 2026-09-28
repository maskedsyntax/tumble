import Foundation
import Testing
import TumbleKit
@testable import Tumble

@MainActor
struct EditDraftStoreTests {
    @Test func replacementUsesTheInitialRecipeAndRemovesOldSource() async throws {
        let root = temporaryRoot()
        let store = EditDraftStore(rootOverride: root)
        let first = try await store.create(
            imageData: Data([1, 2, 3]),
            source: .library,
            recipe: EditRecipe(stockID: "fadedInstant")
        )
        let replacementRecipe = HomeEditIntent(
            entryPoint: .postcardCard,
            initialFilmID: "silver",
            intendedFormat: .postcard
        ).initialRecipe
        let second = try await store.create(
            imageData: Data([4, 5, 6]),
            source: .library,
            recipe: replacementRecipe
        )

        #expect(store.activeDraft?.id == second.id)
        #expect(second.recipe.stockID == "silver")
        #expect(second.recipe.frameStyle == .classicInstant)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent(first.sourceFile).path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent(second.sourceFile).path))
    }

    @Test func failedReplacementLeavesExistingDraftRecoverable() async throws {
        let root = temporaryRoot()
        let store = EditDraftStore(rootOverride: root)
        let first = try await store.create(
            imageData: Data([1, 2, 3]),
            source: .library,
            recipe: EditRecipe(stockID: "fadedInstant")
        )

        await #expect(throws: DraftCreationError.self) {
            try await store.create(
                imageData: Data(),
                source: .library,
                recipe: EditRecipe(stockID: "silver")
            )
        }

        #expect(store.activeDraft == first)
        #expect(await store.sourceData(for: first) == Data([1, 2, 3]))
    }

    private func temporaryRoot() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TumbleDraftTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
