import Foundation

#if canImport(ActivityKit)
@preconcurrency import ActivityKit

public final class TumbleCameraActivityCoordinator {
    private var activity: Activity<TumbleCameraActivityAttributes>?

    public init() {}

    public var canShowLiveActivity: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public func start(remainingLabel: String, capturedCount: Int) {
        guard canShowLiveActivity else { return }

        if let activity {
            let content = Self.content(remainingLabel: remainingLabel, capturedCount: capturedCount, status: "Camera ready")
            Task {
                await activity.update(content)
            }
            return
        }

        do {
            activity = try Activity.request(
                attributes: TumbleCameraActivityAttributes(),
                content: Self.content(remainingLabel: remainingLabel, capturedCount: capturedCount, status: "Camera ready")
            )
        } catch {
            activity = nil
        }
    }

    public func shotSaved(remainingLabel: String, capturedCount: Int) {
        update(remainingLabel: remainingLabel, capturedCount: capturedCount, status: "Shot saved")
    }

    public func update(remainingLabel: String, capturedCount: Int, status: String) {
        guard let activity else { return }
        let content = Self.content(remainingLabel: remainingLabel, capturedCount: capturedCount, status: status)
        Task {
            await activity.update(content)
        }
    }

    public func end() {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func content(remainingLabel: String, capturedCount: Int, status: String) -> ActivityContent<TumbleCameraActivityAttributes.ContentState> {
        ActivityContent(
            state: TumbleCameraActivityAttributes.ContentState(
                remainingLabel: remainingLabel,
                capturedCount: capturedCount,
                status: status
            ),
            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: .now)
        )
    }
}
#else
public final class TumbleCameraActivityCoordinator {
    public init() {}
    public var canShowLiveActivity: Bool { false }
    public func start(remainingLabel: String, capturedCount: Int) {}
    public func shotSaved(remainingLabel: String, capturedCount: Int) {}
    public func update(remainingLabel: String, capturedCount: Int, status: String) {}
    public func end() {}
}
#endif
