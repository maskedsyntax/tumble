import SwiftUI
import CoreMotion

/// Shared, ref-counted device-motion source that drives subtle parallax depth.
/// One `CMMotionManager` for the whole app; updates stop when nothing is on
/// screen. Device-motion is unavailable on the Simulator, so this is a no-op
/// there (offsets stay zero).
@MainActor
@Observable
public final class ParallaxMotion {
    public static let shared = ParallaxMotion()

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var subscribers = 0

    /// Normalized attitude in roughly −1…1.
    public private(set) var roll: Double = 0
    public private(set) var pitch: Double = 0

    private init() {}

    public func subscribe() {
        subscribers += 1
        guard subscribers == 1, manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.roll = max(-1, min(1, motion.attitude.roll / 0.6))
            self.pitch = max(-1, min(1, motion.attitude.pitch / 0.6))
        }
    }

    public func unsubscribe() {
        subscribers = max(0, subscribers - 1)
        if subscribers == 0 {
            manager.stopDeviceMotionUpdates()
            roll = 0
            pitch = 0
        }
    }
}

public extension View {
    /// Offsets the view a few points with device tilt for depth. Honors Reduce
    /// Motion and stops updates when off-screen.
    func parallax(_ magnitude: CGFloat = 8) -> some View {
        modifier(ParallaxEffect(magnitude: magnitude))
    }
}

private struct ParallaxEffect: ViewModifier {
    let magnitude: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = ParallaxMotion.shared
    @State private var subscribed = false

    func body(content: Content) -> some View {
        content
            .offset(
                x: reduceMotion ? 0 : CGFloat(motion.roll) * magnitude,
                y: reduceMotion ? 0 : CGFloat(motion.pitch) * magnitude
            )
            .animation(.easeOut(duration: 0.15), value: motion.roll)
            .animation(.easeOut(duration: 0.15), value: motion.pitch)
            .onAppear {
                guard !reduceMotion, !subscribed else { return }
                subscribed = true
                motion.subscribe()
            }
            .onDisappear {
                guard subscribed else { return }
                subscribed = false
                motion.unsubscribe()
            }
    }
}
