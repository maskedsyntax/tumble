import Foundation
import UserNotifications

/// Schedules the daily "your fresh roll is ready" nudge — the habit loop around
/// the morning reset. A single repeating local notification; no server, no
/// account, no location. Permission is requested value-first (after the shooter
/// develops their first print), never on cold launch.
@MainActor
public enum RollNotificationScheduler {
    private static let requestID = "tumble.freshRoll.daily"
    private static let askedKey = "tumble.notif.asked"
    private static let morningHour = 8

    /// Whether we've already surfaced the permission ask once.
    public static var hasAsked: Bool {
        UserDefaults.standard.bool(forKey: askedKey)
    }

    public static var authorizationStatus: UNAuthorizationStatus {
        get async {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
    }

    /// Ask for permission (once) and, if granted, schedule the daily nudge.
    @discardableResult
    public static func requestAndSchedule() async -> Bool {
        UserDefaults.standard.set(true, forKey: askedKey)
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        if granted { schedule() }
        return granted
    }

    /// (Re)schedule the daily 08:00 local reminder.
    public static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = "Your fresh roll is ready"
        content.body = "Twelve new shots are waiting."
        content.sound = .default

        var when = DateComponents()
        when.hour = morningHour
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestID])
        center.add(request)
    }

    public static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
    }
}
