import SwiftUI
import UIKit

/// One vocabulary for touch feedback, so the same kind of moment always
/// feels the same: picking an option, crossing a detent, finishing a save.
enum Haptics {
    /// Moving between discrete options: films, chips, segments.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A light detent, such as straighten crossing zero or the shutter.
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

/// Shared animation timing. With Reduce Motion on, movement is replaced by
/// a short cross-fade rather than removed outright.
enum Motion {
    static let snappy: Animation = .snappy(duration: 0.22)
    static let fade: Animation = .easeOut(duration: 0.15)

    static func spring(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : snappy
    }
}
