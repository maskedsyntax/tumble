import Foundation

public enum ReviewPromptPolicy {
    public static let requiredExports = 3
    public static let minimumAge: TimeInterval = 7 * 24 * 60 * 60

    public static func isEligible(
        successfulExports: Int,
        installedAt: Date?,
        now: Date,
        currentVersion: String,
        requestedVersion: String?
    ) -> Bool {
        guard successfulExports >= requiredExports,
              requestedVersion != currentVersion,
              let installedAt,
              now.timeIntervalSince(installedAt) >= minimumAge
        else { return false }
        return true
    }
}
