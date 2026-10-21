import Foundation
import SwiftData
import Testing
import TumbleKit
@testable import Tumble

@MainActor
struct DrawerArchiveTests {
    @Test func savingThenSharingADraftKeepsOnePrintWithItsEdit() async throws {
        let container = try PhotoStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let capturedAt = Date(timeIntervalSince1970: 1_000_000)
        let recipe = EditRecipe(stockID: "silver", straighten: 4, frameID: PostcardFrameStyle.classicInstant.rawValue, note: "Lisbon")
        let draft = EditDraft(sourceFile: "source.jpg", sourceKind: .camera, capturedAt: capturedAt, recipe: recipe)

        await DrawerArchive.keep(draft: draft, recipe: recipe, source: Data([1, 2, 3]), finished: Data([4, 5]), in: context)
        await DrawerArchive.keep(draft: draft, recipe: recipe, source: Data([1, 2, 3]), finished: Data([6, 7]), in: context)

        let prints = try context.fetch(FetchDescriptor<Photo>())
        #expect(prints.count == 1)
        let print = try #require(prints.first)
        defer { PhotoStore.deleteImages(for: print) }
        #expect(print.isStudioEdit)
        #expect(print.isDeveloped)
        #expect(print.filmStock.id == "silver")
        #expect(print.frameStyle == .classicInstant)
        #expect(print.edit == PrintEdit(recipe: recipe, sourceKind: .camera, capturedAt: capturedAt))
        #expect(PhotoStore.loadImageData(named: print.rawImageName) == Data([1, 2, 3]))
        #expect(PhotoStore.loadImageData(named: print.developedImageName) == Data([6, 7]))
    }

    @Test func rollPrintsAreNotStudioEdits() {
        #expect(!Photo().isStudioEdit)
        #expect(Photo().edit == nil)
    }
}
