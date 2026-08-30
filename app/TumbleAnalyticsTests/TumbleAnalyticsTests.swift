import Foundation
import Testing
@testable import TumbleAnalytics
import TumbleKit

@MainActor
struct TumbleAnalyticsTests {
    @Test func eventContractUsesStableNamesAndProperties() {
        let event = AnalyticsEvent.photoDeveloped(
            source: "lockscreen",
            method: "shake",
            filmStockID: "golden-hour"
        )

        #expect(event.name == "photo_developed")
        #expect(event.properties["source"] as? String == "lockscreen")
        #expect(event.properties["method"] as? String == "shake")
        #expect(event.properties["film_stock_id"] as? String == "golden-hour")
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
        for key in ["caption", "photo_id", "raw_image_name", "free_text_note", "image_data"] {
            #expect(TumbleAnalytics.isForbiddenProperty(key))
        }
        for key in ["film_stock_id", "frame_style", "photo_count", "source_screen"] {
            #expect(!TumbleAnalytics.isForbiddenProperty(key))
        }
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
