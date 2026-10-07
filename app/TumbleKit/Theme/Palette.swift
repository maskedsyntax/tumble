import SwiftUI

/// The "graincore" palette, ported verbatim from `web/src/app/globals.css`.
/// Slate-blue base (#2E4052) with a warm gold glow (#DFAB68); texture comes
/// from film grain, never blur.
public enum Palette {
    public static let blue = Color(hex: 0x2E4052)
    public static let blueDeep = Color(hex: 0x223140)
    public static let blueLift = Color(hex: 0x3A5164)

    public static let cream = Color(hex: 0xF6EFE2)
    public static let creamDim = Color(hex: 0xE9DCC4)
    public static let ink = Color(hex: 0x1E2A34)

    public static let amber = Color(hex: 0xDFAB68)
    public static let gold = Color(hex: 0xDFAB68)
    public static let charcoalDeep = Color(hex: 0x202D39)

    /// The cream stock a developed print is mounted on.
    public static let printStock = Color(hex: 0xF4ECDA)

    // MARK: Editor surfaces
    //
    // Editing screens sit on near-neutral graphite so film color is judged
    // against something that does not tint it. The navy "graincore" palette
    // above stays for brand surfaces (Home, introduction, paywall).

    /// Behind the photograph being edited.
    public static let canvas = Color(hex: 0x0D0E10)
    /// Docks, bars and sheets on editing screens.
    public static let surface = Color(hex: 0x16181B)
    /// Chips, fields and thumbnails placed on `surface`.
    public static let surfaceRaised = Color(hex: 0x1F2226)
    /// One-pixel separators on either palette.
    public static let hairline = cream.opacity(0.08)

    // MARK: Text

    public static let textPrimary = cream
    /// Supporting copy. Meets 4.5:1 on `surface`, `canvas` and `blueDeep`.
    public static let textSecondary = cream.opacity(textSecondaryOpacity)
    /// De-emphasised labels; never used below 13 pt.
    public static let textTertiary = cream.opacity(textTertiaryOpacity)

    public static let textSecondaryOpacity = 0.72
    public static let textTertiaryOpacity = 0.56
}

public extension Color {
    /// Build a `Color` from a 24-bit `0xRRGGBB` literal.
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
