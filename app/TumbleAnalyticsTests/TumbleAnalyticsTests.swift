import Foundation
import Testing
@testable import TumbleAnalytics
import TumbleKit

@MainActor
struct TumbleAnalyticsTests {
    @Test func eventContractUsesStableNamesAndProperties() {
        let event = AnalyticsEvent.studioOpened(source: "library", initialFilmStockID: "goldenHour")

        #expect(event.name == "studio_opened")
        #expect(event.properties["source"] as? String == "library")
        #expect(event.properties["initial_film_stock_id"] as? String == "goldenHour")
    }

    @Test func homeEntryEventContainsOnlySafeRoutingProperties() {
        let event = AnalyticsEvent.homeEntrySelected(
            entryPoint: "film_card",
            filmStockID: "silver",
            intendedFormat: nil
        )
        #expect(event.name == "home_entry_selected")
        #expect(event.properties["entry_point"] as? String == "film_card")
        #expect(event.properties["film_stock_id"] as? String == "silver")
        #expect(event.properties["intended_format"] == nil)
        #expect(TumbleAnalytics.schemaVersion == 3)
    }

    @Test func optionalPropertiesAreOmitted() {
        let event = AnalyticsEvent.paywallViewed(
            type: "roll",
            source: "about",
            packID: nil,
            remainingShots: nil
        )

        #expect(event.properties["pack_id"] == nil)
        #expect(event.properties["remaining_shots"] == nil)
    }

    @Test func sensitivePropertyNamesAreRejected() {
        for key in ["caption", "photo_id", "raw_image_name", "free_text_note", "image_data", "file_name", "crop_coordinates", "pixel_width", "note_content"] {
            #expect(TumbleAnalytics.isForbiddenProperty(key))
        }
        for key in ["film_stock_id", "frame_style", "photo_count", "source_screen", "has_note"] {
            #expect(!TumbleAnalytics.isForbiddenProperty(key))
        }
    }

    @Test func threeOneFunnelUsesStableOrderedNames() {
        let funnel: [AnalyticsEvent] = [
            .homeViewed,
            .sourceSelected(source: "library"),
            .studioOpened(source: "library", initialFilmStockID: "fadedInstant"),
            .finishOpened(filmStockID: "fadedInstant", premium: false),
            .exportCompleted(format: "photo", action: "save", frameStyle: "none"),
        ]
        #expect(funnel.map(\.name) == [
            "home_viewed", "source_selected", "studio_opened", "finish_opened", "export_completed",
        ])
    }

    @Test func postcardAnalyticsRecordsPresenceButNeverContent() {
        let event = AnalyticsEvent.postcardConfigured(frameStyle: "classic", hasNote: true)
        #expect(event.properties["has_note"] as? Bool == true)
        #expect(event.properties["note"] == nil)
        #expect(event.properties["note_content"] == nil)
    }

    @Test func screensHaveUniqueNames() {
        let names = AnalyticsScreen.allCases.map(\.rawValue)
        #expect(Set(names).count == names.count)
    }

    @Test func commerceOutcomesUseDashboardSafeValues() {
        #expect(PurchaseOutcome.allCases.map(\.rawValue) == [
            "completed", "cancelled", "pending", "unverified", "error",
        ])
        #expect(RestoreOutcome.allCases.map(\.rawValue) == ["completed", "error"])
    }
}
