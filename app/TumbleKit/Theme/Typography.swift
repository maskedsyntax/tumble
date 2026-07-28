import SwiftUI
import UIKit
import CoreText

private final class TumbleKitBundleToken {}

/// Type ramp mirroring the site: Fraunces (display serif) for headlines,
/// Inter (sans) for body, Caveat (script) for handwritten notes on prints.
/// If the bundled font files are not present the system serif ("New York"),
/// default sans, and a rounded/hand-style stand in, so the app always
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

    /// Handwritten script face for notes scribbled on a print. Caveat is
    /// bundled with TumbleKit and registered on first use.
    public static func script(_ size: CGFloat) -> Font {
        registerBundledFontsIfNeeded()
        if fontExists("Caveat") {
            return .custom("Caveat", size: size)
        }
        return .system(size: size, weight: .regular, design: .serif).italic()
    }

    private static func fontExists(_ name: String) -> Bool {
        UIFont(name: name, size: 12) != nil
    }

    /// Fonts inside a framework bundle are not picked up via the app's
    /// Info.plist, so register them with Core Text lazily (once, via a
    /// constant initializer which Swift guarantees runs atomically).
    private static let bundledFontsRegistered: Bool = {
        let bundle = Bundle(for: TumbleKitBundleToken.self)
        for name in ["Caveat"] {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        return true
    }()

    private static func registerBundledFontsIfNeeded() {
        _ = bundledFontsRegistered
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
