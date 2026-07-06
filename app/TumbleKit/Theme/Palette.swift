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
