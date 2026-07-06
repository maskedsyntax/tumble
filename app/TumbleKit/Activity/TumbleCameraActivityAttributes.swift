import Foundation

#if canImport(ActivityKit)
@preconcurrency import ActivityKit

public struct TumbleCameraActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var remainingLabel: String
        public var capturedCount: Int
        public var status: String

        public init(remainingLabel: String, capturedCount: Int, status: String) {
            self.remainingLabel = remainingLabel
            self.capturedCount = capturedCount
            self.status = status
        }
    }

    public var startedAt: Date

    public init(startedAt: Date = .now) {
        self.startedAt = startedAt
    }
}
#endif
