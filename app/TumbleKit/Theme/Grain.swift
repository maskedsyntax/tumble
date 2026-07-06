import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Film grain — the primary background texture ("graincore"). Generated once
/// as a small tileable monochrome noise image and cached. Mirrors the
/// fractal-noise SVG the site paints in `body::after`.
public enum Grain {
    public static let shared: UIImage = make(size: 180)

    private static func make(size: CGFloat) -> UIImage {
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let extent = CGRect(x: 0, y: 0, width: size, height: size)

        let noise = CIFilter.randomGenerator().outputImage ?? CIImage(color: .gray)
        // Desaturate to pure luminance grain and lift into mid-tones so it
        // reads as overlay texture rather than harsh salt-and-pepper.
        let mono = noise
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: 0,
                kCIInputContrastKey: 0.7,
            ])
            .cropped(to: extent)

        guard let cg = context.createCGImage(mono, from: extent) else {
            return UIImage()
        }
        return UIImage(cgImage: cg)
    }
}

/// Tiles the grain across a region with an overlay blend at low opacity —
/// the same treatment as the site (opacity ~0.22, mix-blend-mode: overlay).
public struct GrainOverlay: View {
    private let opacity: Double
    public init(opacity: Double = 0.22) { self.opacity = opacity }

    public var body: some View {
        Image(uiImage: Grain.shared)
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}
