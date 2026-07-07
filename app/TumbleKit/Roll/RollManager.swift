import Foundation
import Observation

/// The daily Roll - the product's whole thesis. Grants a fresh quota of shots
/// each morning (local midnight), enforces it, and never nags. Backed by the
/// App Group defaults so the lock-screen capture extension decrements the very
/// same counter.
///
/// Dependencies (defaults, calendar, clock) are injectable so the rollover and
/// quota rules are unit-testable without a device.
@Observable
public final class RollManager {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let now: () -> Date

    private enum Key {
        static let consumed = "roll.consumedToday"
        static let lastReset = "roll.lastResetDayStart"
        static let entitlement = "roll.entitlement"
    }

    /// The owned tier; drives the quota. Set by `PurchaseManager` in the app,
    /// and mirrored into the App Group so the lock-screen extension reads the
    /// same quota.
    public var entitlement: Entitlement {
        didSet {
            defaults.set(entitlement.rawValue, forKey: Key.entitlement)
            rolloverIfNeeded()
        }
    }

    /// Shots taken so far today.
    public private(set) var consumedToday: Int
    @ObservationIgnored private var lastResetDayStart: Date

    /// - Parameter loadsEntitlementFromDefaults: the lock-screen extension has
    ///   no StoreKit; it reads the tier the app last mirrored into the group.
    public init(
        defaults: UserDefaults = AppGroup.defaults,
        calendar: Calendar = .current,
        entitlement: Entitlement = .free,
        loadsEntitlementFromDefaults: Bool = false,
        now: @escaping () -> Date = { Date() }
    ) {
        self.defaults = defaults
        self.calendar = calendar
        if loadsEntitlementFromDefaults,
           let raw = defaults.string(forKey: Key.entitlement),
           let stored = Entitlement(rawValue: raw) {
            self.entitlement = stored
        } else {
            self.entitlement = entitlement
        }
        self.now = now
        self.consumedToday = defaults.integer(forKey: Key.consumed)
        let stored = defaults.double(forKey: Key.lastReset)
        self.lastResetDayStart = stored > 0
            ? Date(timeIntervalSinceReferenceDate: stored)
            : .distantPast
        rolloverIfNeeded()
    }

    // MARK: Derived state

    /// Daily allowance; `nil` for Unlimited.
    public var quota: Int? { entitlement.dailyQuota }
    public var isUnlimited: Bool { quota == nil }

    /// Shots left today; `nil` for Unlimited.
    public var remaining: Int? {
        quota.map { max(0, $0 - consumedToday) }
    }

    public var canShoot: Bool {
        isUnlimited || (remaining ?? 0) > 0
    }

    /// Quiet counter copy for the viewfinder, e.g. "7 left today".
    public var remainingLabel: String {
        if isUnlimited { return "Unlimited" }
        return "\(remaining ?? 0) left today"
    }

    public var remainingShotsSentence: String {
        if isUnlimited { return "Unlimited shots." }
        return Self.shotsLeftSentence(for: remaining ?? 0)
    }

    public static func shotsLeftSentence(for count: Int) -> String {
        "\(count) \(count == 1 ? "shot" : "shots") left today."
    }

    // MARK: Actions

    /// Call when the app becomes active to pick up a midnight rollover.
    public func refresh() { rolloverIfNeeded() }

    /// Spend one shot. Returns false when the roll is empty (caller shows the
    /// calm "fresh at sunrise" state - never a hard modal).
    @discardableResult
    public func consumeShot() -> Bool {
        rolloverIfNeeded()
        guard canShoot else { return false }
        if !isUnlimited {
            consumedToday += 1
            defaults.set(consumedToday, forKey: Key.consumed)
        }
        return true
    }

    private func rolloverIfNeeded() {
        let today = calendar.startOfDay(for: now())
        guard today != lastResetDayStart else { return }
        consumedToday = 0
        lastResetDayStart = today
        defaults.set(0, forKey: Key.consumed)
        defaults.set(today.timeIntervalSinceReferenceDate, forKey: Key.lastReset)
    }
}
