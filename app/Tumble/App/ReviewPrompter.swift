import StoreKit
import UIKit

@MainActor
final class ReviewPrompter {
    static let shared = ReviewPrompter()

    private let defaults = UserDefaults.standard
    private let developedCountKey = "tumble.review.developedCount"
    private let savedCountKey = "tumble.review.savedCount"
    private let requestCountKey = "tumble.review.requestCount"
    private let lastRequestKey = "tumble.review.lastRequest"

    private init() {}

    func recordDevelopedPrint() {
        let count = defaults.integer(forKey: developedCountKey) + 1
        defaults.set(count, forKey: developedCountKey)

        if count >= 3 {
            requestIfAppropriate()
        }
    }

    func recordSavedToPhotos() {
        let count = defaults.integer(forKey: savedCountKey) + 1
        defaults.set(count, forKey: savedCountKey)
        requestIfAppropriate()
    }

    private func requestIfAppropriate() {
        guard defaults.integer(forKey: requestCountKey) < 2 else { return }

        if let lastRequest = defaults.object(forKey: lastRequestKey) as? Date,
           Date().timeIntervalSince(lastRequest) < 90 * 24 * 60 * 60 {
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        defaults.set(defaults.integer(forKey: requestCountKey) + 1, forKey: requestCountKey)
        defaults.set(Date(), forKey: lastRequestKey)
        SKStoreReviewController.requestReview(in: scene)
    }
}
