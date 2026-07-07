import SwiftUI

/// The atmospheric backdrop shared across the app - a direct port of the
/// site's `body` background: a diagonal slate gradient, off-center gold and
/// lifted-blue radial "blobs" pushed past the edges for an organic contour,
/// and a film-grain overlay. No blur; texture comes from grain.
public struct GraincoreBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            // Base diagonal slate gradient (linear-gradient 158deg on the site).
            LinearGradient(
                colors: [Color(hex: 0x2B3C4C), Color(hex: 0x263646), Color(hex: 0x21303F)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Off-center glow blobs - gold lower-left, gold upper-right, and
            // lifted-blue on the loose corners.
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    blob(Palette.gold.opacity(0.42), at: CGPoint(x: 0.04 * w, y: 0.92 * h), radius: 0.7 * w)
                    blob(Palette.gold.opacity(0.30), at: CGPoint(x: 0.98 * w, y: 0.02 * h), radius: 0.62 * w)
                    blob(Palette.blueLift.opacity(0.42), at: CGPoint(x: 1.02 * w, y: 0.80 * h), radius: 0.7 * w)
                    blob(Palette.blueLift.opacity(0.34), at: CGPoint(x: -0.02 * w, y: 0.12 * h), radius: 0.6 * w)
                }
            }
            .allowsHitTesting(false)

            GrainOverlay()
        }
        .ignoresSafeArea()
        .background(Palette.blue)
    }

    private func blob(_ color: Color, at center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }
}
