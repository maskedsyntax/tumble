import CoreGraphics

/// Shared visual-density values for the editing flow. Interactive controls
/// may draw smaller chrome inside these measurements, but retain a 44-point
/// hit region for touch and accessibility.
enum EditorChromeMetrics {
    static let minimumHitTarget: CGFloat = 44
    static let topBarHeight: CGFloat = 44
    static let topBarControlVisual: CGFloat = 32
    static let topBarPrimaryVisualHeight: CGFloat = 34
    static let horizontalPadding: CGFloat = 12
    static let canvasHorizontalPadding: CGFloat = 8
    static let canvasVerticalPadding: CGFloat = 6
    static let canvasCornerRadius: CGFloat = 18

    // The film browser shows one collection at a time; the amount adjustment
    // replaces that browser temporarily so the canvas remains the focal point.
    static let studioFilmDockHeight: CGFloat = 224
    static let studioAmountDockHeight: CGFloat = 134
    static let studioCompositionDockHeight: CGFloat = 160
    static let studioFreeformDockHeight: CGFloat = 234
    static let studioFilmAccessibilityDockHeight: CGFloat = 258
    static let studioCompositionAccessibilityDockHeight: CGFloat = 190
    static let dockHorizontalPadding: CGFloat = 10
    static let dockVerticalPadding: CGFloat = 6
    static let dockGap: CGFloat = 6
    static let toolSwitcherHeight: CGFloat = 54
    static let filmBrowserHeaderHeight: CGFloat = 48

    static let filmThumbnailWidth: CGFloat = 96
    static let filmThumbnailHeight: CGFloat = 96

    static let finishFormatRowHeight: CGFloat = 54
    static let finishPhotoDockHeight: CGFloat = 54
    static let finishPostcardDockHeight: CGFloat = 108
    static let finishAccessibilityDockHeight: CGFloat = 164
    static let finishActionVisualHeight: CGFloat = 46
    static let finishActionCornerRadius: CGFloat = 11
}
