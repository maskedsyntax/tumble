import SwiftUI
import UIKit

/// Type ramp mirroring the site: Fraunces (display serif) for headlines,
/// Inter (sans) for body. If the bundled font files are not present the
/// system serif ("New York") and default sans stand in, so the app always
/// builds and renders sensibly.
public enum Typography {
    private static let hasFraunces = fontExists("Fraunces")
    private static let hasInter = fontExists("Inter")

    /// Serif display face for headlines and the print captions.
    public static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        if hasFraunces {
            return .custom("Fraunces", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    /// Sans body face.
    public static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if hasInter {
            return .custom("Inter", size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .default)
    }

    private static func fontExists(_ name: String) -> Bool {
        UIFont(name: name, size: 12) != nil
    }
}

public extension Text {
    /// Small caps-y kicker used above section headings on the site.
    func kicker() -> some View {
        self.font(Typography.sans(12, weight: .semibold))
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(Palette.amber)
    }
}
