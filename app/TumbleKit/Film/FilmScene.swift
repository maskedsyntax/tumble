import UIKit

/// Synthetic "photographs" - the same gradient scenes the site paints in
/// `DrawerMockup`. Used as develop previews and, crucially, as stand-in
/// captures on the Simulator (which has no camera) so the whole capture →
/// develop → Drawer flow is demoable without a device. On a real device these
/// are replaced by actual camera frames.
public enum FilmScene: CaseIterable, Sendable {
    case goldenHour
    case blueHourRooftop
    case sunlitPark
    case beachMorning
    case warmPortrait
    case pinkDusk

    public static func random() -> FilmScene { allCases.randomElement()! }

    /// Render the scene to a UIImage at the given pixel size.
    public func image(size: CGFloat = 1024) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            drawLinear(in: cg, rect: rect)
            drawHighlight(in: cg, rect: rect)
            drawLightLeak(in: cg, rect: rect)
            drawVignette(in: cg, rect: rect)
        }
    }

    /// A soft warm light-leak from a corner (screen-blended), the way film
    /// catches stray light — adds depth over the flat gradient.
    private func drawLightLeak(in ctx: CGContext, rect: CGRect) {
        let space = CGColorSpaceCreateDeviceRGB()
        let leak = self.leak
        let colors = [leak.color.cgColor, leak.color.withAlphaComponent(0).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.setBlendMode(.screen)
        let center = CGPoint(x: rect.width * leak.center.x, y: rect.height * leak.center.y)
        ctx.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: rect.width * 0.6,
            options: []
        )
        ctx.restoreGState()
    }

    /// A gentle vignette so the frame reads as a photograph, not a swatch.
    private func drawVignette(in ctx: CGContext, rect: CGRect) {
        let space = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(white: 0, alpha: 0).cgColor,
            UIColor(white: 0.04, alpha: 0.4).cgColor,
        ] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.55, 1]) else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY * 0.96)
        ctx.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: rect.width * 0.2,
            endCenter: center, endRadius: rect.width * 0.74,
            options: [.drawsAfterEndLocation]
        )
    }

    private func drawLinear(in ctx: CGContext, rect: CGRect) {
        let space = CGColorSpaceCreateDeviceRGB()
        let stops = spec.linear
        let colors = stops.map { UIColor($0.0).cgColor } as CFArray
        let locations = stops.map { $0.1 }
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }

    private func drawHighlight(in ctx: CGContext, rect: CGRect) {
        guard let hl = spec.highlight else { return }
        let space = CGColorSpaceCreateDeviceRGB()
        let colors = [hl.color.cgColor, hl.color.withAlphaComponent(0).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
        let center = CGPoint(x: rect.width * hl.center.x, y: rect.height * hl.center.y)
        ctx.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: rect.width * hl.radius,
            options: []
        )
    }

    /// Warm light-leak colour and corner, per scene.
    private var leak: (color: UIColor, center: CGPoint) {
        switch self {
        case .goldenHour: (UIColor(0xFFC178, 0.32), CGPoint(x: 0.9, y: 0.14))
        case .blueHourRooftop: (UIColor(0xFFB870, 0.24), CGPoint(x: 0.12, y: 0.16))
        case .sunlitPark: (UIColor(0xFFF0B0, 0.3), CGPoint(x: 0.85, y: 0.1))
        case .beachMorning: (UIColor(0xFFE8C0, 0.26), CGPoint(x: 0.9, y: 0.12))
        case .warmPortrait: (UIColor(0xFFD0A0, 0.34), CGPoint(x: 0.14, y: 0.12))
        case .pinkDusk: (UIColor(0xFFC8A0, 0.3), CGPoint(x: 0.86, y: 0.85))
        }
    }

    private var spec: SceneSpec {
        switch self {
        case .goldenHour:
            SceneSpec(
                linear: [(0xF4B46A, 0), (0xE08A58, 0.34), (0x9C5A5C, 0.54), (0x40384A, 0.72), (0x263040, 1)],
                highlight: (UIColor(0xFFD68C, 0.95), CGPoint(x: 0.5, y: 0.3), 0.6))
        case .blueHourRooftop:
            SceneSpec(
                linear: [(0x223D5C, 0), (0x315679, 0.42), (0x5C6F82, 0.62), (0x8A7566, 0.82), (0xC1946A, 1)],
                highlight: (UIColor(0xF0B46E, 0.55), CGPoint(x: 0.72, y: 0.82), 0.6))
        case .sunlitPark:
            SceneSpec(
                linear: [(0xD7E6CF, 0), (0xA9C58F, 0.38), (0x6F8D55, 0.66), (0x3F5738, 1)],
                highlight: (UIColor(0xFFECB4, 0.8), CGPoint(x: 0.3, y: 0.18), 0.6))
        case .beachMorning:
            SceneSpec(
                linear: [(0xA9CFE0, 0), (0xC9DFE4, 0.34), (0xE7DCC2, 0.56), (0xD0A86A, 0.78), (0xB8895C, 1)],
                highlight: (UIColor(0xFFF0CD, 0.85), CGPoint(x: 0.68, y: 0.22), 0.55))
        case .warmPortrait:
            SceneSpec(
                linear: [(0xECC39A, 0), (0xC08A6C, 0.46), (0x6F4A48, 0.78), (0x3A2B30, 1)],
                highlight: (UIColor(0xECC39A, 0.6), CGPoint(x: 0.48, y: 0.4), 0.5))
        case .pinkDusk:
            SceneSpec(
                linear: [(0x6F7FA6, 0), (0xB98AA0, 0.38), (0xD99A86, 0.62), (0xCAA06E, 1)],
                highlight: (UIColor(0xFFC896, 0.7), CGPoint(x: 0.5, y: 0.78), 0.6))
        }
    }
}

private struct SceneSpec {
    let linear: [(UInt32, CGFloat)]
    let highlight: (color: UIColor, center: CGPoint, radius: CGFloat)?

    init(linear: [(UInt32, CGFloat)], highlight: (UIColor, CGPoint, CGFloat)?) {
        self.linear = linear
        self.highlight = highlight.map { ($0.0, $0.1, $0.2) }
    }
}

extension UIColor {
    fileprivate convenience init(_ hex: UInt32, _ alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
