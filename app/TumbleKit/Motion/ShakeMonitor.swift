import Foundation
import CoreMotion
import Observation

/// Reads the accelerometer and reports shake "jolts" — the energy that drives
/// shake-to-develop. Gravity (~1g) is subtracted so only real motion counts.
///
/// The accelerometer is unavailable on the Simulator; `isAvailable` lets the UI
/// fall back to a press-and-hold develop instead (also the Reduce Motion path).
@MainActor
@Observable
public final class ShakeMonitor {
    @ObservationIgnored private let manager = CMMotionManager()
    public let isAvailable: Bool

    /// Called on each jolt with a normalized energy (~0…1).
    @ObservationIgnored public var onShake: ((Double) -> Void)?

    public init() {
        isAvailable = manager.isAccelerometerAvailable
    }

    public func start() {
        guard isAvailable, !manager.isAccelerometerActive else { return }
        manager.accelerometerUpdateInterval = 1.0 / 50.0
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let a = data?.acceleration else { return }
            let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            let jolt = magnitude - 1.0 // remove gravity baseline
            if jolt > 0.12 {
                self.onShake?(min(1, jolt / 2.0))
            }
        }
    }

    public func stop() {
        manager.stopAccelerometerUpdates()
    }
}
