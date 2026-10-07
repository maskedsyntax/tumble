import CoreGraphics

/// Shared visual-density values for the editing flow. Interactive controls
/// may draw smaller chrome inside these measurements, but retain a 44-point
/// hit region for touch and accessibility.
enum EditorChromeMetrics {
    static let minimumHitTarget: CGFloat = 44
    static let topBarHeight: CGFloat = 52
    static let topBarPrimaryVisualHeight: CGFloat = 36
    static let iconButtonVisual: CGFloat = 36
    static let segmentVisualHeight: CGFloat = 34
    static let chipVisualHeight: CGFloat = 32
    static let horizontalPadding: CGFloat = 12
    static let canvasHorizontalPadding: CGFloat = 16
    static let canvasVerticalPadding: CGFloat = 12
    static let overlayInset: CGFloat = 26

    // Studio keeps one dock height for every tool and panel, so the photo
    // never jumps when switching between Film, Amount, and Crop.
    static let studioDockHeight: CGFloat = 242
    static let studioDockLargeTextHeight: CGFloat = 264
    static let studioDockAccessibilityHeight: CGFloat = 300
    static let toolSwitcherHeight: CGFloat = 58

    static let filmThumbnailWidth: CGFloat = 72
    static let filmThumbnailHeight: CGFloat = 90

    static let frameTileWidth: CGFloat = 64
    static let finishActionHeight: CGFloat = 50
}
