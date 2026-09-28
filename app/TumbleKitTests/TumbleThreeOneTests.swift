import Foundation
import Testing
@testable import TumbleKit

struct TumbleThreeOneTests {
    @Test func editingNavigationStatesRemainDistinct() {
        let id = UUID()
        #expect(StudioRoute.home != .camera)
        #expect(StudioRoute.studio(id) != .finish(id))
    }

    @Test func shippedDraftRecipeRemainsDecodable() throws {
        let json = """
        {"stockID":"warmArchive","intensity":0.72,"cropPreset":"freeform","crop":{"x":0.1,"y":0.2,"width":0.7,"height":0.6},"quarterTurns":3,"frameID":"classic","note":"Wish you were here"}
        """.data(using: .utf8)!

        let recipe = try JSONDecoder().decode(EditRecipe.self, from: json)
        #expect(recipe.stockID == "warmArchive")
        #expect(recipe.frameID == "classic")
        #expect(recipe.note == "Wish you were here")
        #expect(recipe.quarterTurns == 3)
    }

    @Test func reviewPromptRequiresThirdExportAndSevenDays() {
        let installed = Date(timeIntervalSince1970: 1_000)
        let daySix = installed.addingTimeInterval(6 * 24 * 60 * 60)
        let daySeven = installed.addingTimeInterval(7 * 24 * 60 * 60)

        #expect(!ReviewPromptPolicy.isEligible(successfulExports: 2, installedAt: installed, now: daySeven, currentVersion: "3.1.0", requestedVersion: nil))
        #expect(!ReviewPromptPolicy.isEligible(successfulExports: 3, installedAt: installed, now: daySix, currentVersion: "3.1.0", requestedVersion: nil))
        #expect(ReviewPromptPolicy.isEligible(successfulExports: 3, installedAt: installed, now: daySeven, currentVersion: "3.1.0", requestedVersion: nil))
    }

    @Test func reviewPromptOccursAtMostOncePerVersion() {
        let installed = Date(timeIntervalSince1970: 1_000)
        let now = installed.addingTimeInterval(10 * 24 * 60 * 60)
        #expect(!ReviewPromptPolicy.isEligible(successfulExports: 5, installedAt: installed, now: now, currentVersion: "3.1.0", requestedVersion: "3.1.0"))
        #expect(ReviewPromptPolicy.isEligible(successfulExports: 5, installedAt: installed, now: now, currentVersion: "3.1.1", requestedVersion: "3.1.0"))
    }

    @Test func exportGateFollowsTheActiveFilm() {
        let free = AccessState.free(legacyPackIDs: [])
        #expect(free.unlocks(FilmStockCatalog.resolve("fadedInstant")))
        #expect(!free.unlocks(FilmStockCatalog.resolve("goldenHour")))
        #expect(AccessState.complete.unlocks(FilmStockCatalog.resolve("goldenHour")))
    }

    @Test func homeIntentRoutesFilmAndPostcardWithoutChangingRecipeShape() {
        let film = HomeEditIntent(entryPoint: .filmCard, initialFilmID: "silver")
        #expect(film.initialRecipe.stockID == "silver")
        #expect(film.initialRecipe.frameStyle == .none)

        let postcard = HomeEditIntent(
            entryPoint: .postcardCard,
            initialFilmID: "fadedInstant",
            intendedFormat: .postcard
        )
        #expect(postcard.initialRecipe.frameStyle == .classicInstant)
    }

    @Test func postcardMetricsCoverNotesAndStayInsideExportBounds() {
        #expect(PostcardFrameStyle.classicInstant.renderAspect(hasNote: true)
            > PostcardFrameStyle.classicInstant.renderAspect(hasNote: false))
        for style in PostcardFrameStyle.allCases {
            for hasNote in [false, true] {
                let width = style.exportWidth(hasNote: hasNote)
                let height = width * style.renderAspect(hasNote: hasNote)
                #expect(width <= 4096)
                #expect(height <= 4096.001)
            }
        }
    }

    @Test func postcardPreviewFitIncludesClearanceAndShadow() {
        let previewSizes = [
            CGSize(width: 351, height: 344),
            CGSize(width: 366, height: 500),
            CGSize(width: 406, height: 580),
        ]

        for style in PostcardFrameStyle.allCases where style != .none {
            for size in previewSizes {
                for hasNote in [false, true] {
                    let width = style.previewWidth(inside: size, hasNote: hasNote)
                    let visualWidth = width * 1.12
                    let visualHeight = width * (style.renderAspect(hasNote: hasNote) + 0.16)
                    #expect(visualWidth <= size.width - 32.0 + 0.001)
                    #expect(visualHeight <= size.height - 32.0 + 0.001)
                }
            }
        }
    }
}
