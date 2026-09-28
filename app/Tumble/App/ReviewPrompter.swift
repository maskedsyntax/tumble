import StoreKit
import TumbleKit
import UIKit

@MainActor
final class ReviewPrompter {
    static let shared = ReviewPrompter()

    private let defaults = UserDefaults.standard
    private let developedCountKey = "tumble.review.developedCount"
    private let savedCountKey = "tumble.review.savedCount"
    private let installDateKey = "tumble.review.installDate"
    private let requestedVersionKey = "tumble.review.requestedVersion"

    private init() {}

    func recordInstallationIfNeeded(now: Date = Date()) {
        if defaults.object(forKey: installDateKey) == nil {
            defaults.set(now, forKey: installDateKey)
        }
    }

    func recordSuccessfulExport(now: Date = Date()) {
        recordInstallationIfNeeded(now: now)
        let count = defaults.integer(forKey: savedCountKey) + 1
        defaults.set(count, forKey: savedCountKey)
        requestIfAppropriate(now: now)
    }

    func recordDevelopedPrint() {
        let count = defaults.integer(forKey: developedCountKey) + 1
        defaults.set(count, forKey: developedCountKey)

        if count >= 3 {
            requestIfAppropriate()
        }
    }

    func recordSavedToPhotos() {
        recordSuccessfulExport()
    }

    private func requestIfAppropriate(now: Date = Date()) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        guard ReviewPromptPolicy.isEligible(
            successfulExports: defaults.integer(forKey: savedCountKey),
            installedAt: defaults.object(forKey: installDateKey) as? Date,
            now: now,
            currentVersion: version,
            requestedVersion: defaults.string(forKey: requestedVersionKey)
        ) else { return }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        defaults.set(version, forKey: requestedVersionKey)
        SKStoreReviewController.requestReview(in: scene)
    }
}
