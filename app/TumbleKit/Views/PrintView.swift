import SwiftUI
import UIKit

/// A single instant print, mounted on cream stock — the exact treatment from
/// the site's `DrawerMockup`: the photograph, a warm aged grade that grows
/// with age, film grain, a vignette, and a soft sheen. Also renders the blank,
/// face-down state for an undeveloped shot.
///
/// `developProgress` (0…1) drives the shake-to-develop look: it starts washed
/// out and desaturated and settles into full color.
public struct PrintView: View {
    private let image: UIImage?
    private let isDeveloped: Bool
    private let developProgress: Double
    private let age: Double
    private let caption: String?
    private let width: CGFloat

    public init(
        image: UIImage?,
        isDeveloped: Bool,
        developProgress: Double = 1,
        age: Double = 0,
        caption: String? = nil,
        width: CGFloat = 200
    ) {
        self.image = image
        self.isDeveloped = isDeveloped
        self.developProgress = developProgress
        self.age = age
        self.caption = caption
        self.width = width
    }

    public var body: some View {
        VStack(spacing: 0) {
            photo
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: width * 0.01))
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.01)
                        .strokeBorder(.black.opacity(0.15), lineWidth: 0.5)
                )

            if let caption, isDeveloped {
                Text(caption)
                    .font(Typography.display(width * 0.052, weight: .regular))
                    .italic()
                    .foregroundStyle(Palette.ink.opacity(0.7))
                    .padding(.top, width * 0.06)
            }
        }
        .padding(width * 0.06)
        .padding(.bottom, width * 0.09)
        .frame(width: width)
        .background(Palette.printStock)
        .clipShape(RoundedRectangle(cornerRadius: width * 0.025))
        .shadow(color: .black.opacity(0.5), radius: width * 0.06, x: 0, y: width * 0.05)
    }

    @ViewBuilder private var photo: some View {
        if isDeveloped || developProgress > 0 {
            developedPhoto
        } else {
            // Blank, face-down: an undeveloped shot you haven't shaken yet.
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0xE8DFCC), Color(hex: 0xD8CDB4)],
                    startPoint: .top, endPoint: .bottom
                )
                Image(systemName: "hand.draw")
                    .font(.system(size: width * 0.12, weight: .light))
                    .foregroundStyle(Palette.ink.opacity(0.25))
            }
        }
    }

    private var developedPhoto: some View {
        ZStack {
            sceneLayer
            agedGrade
            GrainOverlay(opacity: 0.4)
            vignette
            sheen
        }
        // Develop transition: washed out + desaturated at first, settling in.
        .saturation(developProgress)
        .overlay(Color.white.opacity((1 - developProgress) * 0.65))
        .brightness((1 - developProgress) * 0.18)
    }

    // Warm aged grade — the site formula: warm over cool, both scaling with age.
    private var agedGrade: some View {
        LinearGradient(
            colors: [
                Color(hex: 0xD6965A, opacity: 0.12 + age * 0.24),
                Color(hex: 0x78463C, opacity: 0.06 + age * 0.16),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .blendMode(.multiply)
    }

    private var vignette: some View {
        RadialGradient(
            colors: [.clear, Color(hex: 0x1C1012, opacity: 0.42)],
            center: .init(x: 0.5, y: 0.44),
            startRadius: width * 0.3,
            endRadius: width * 0.72
        )
    }

    private var sheen: some View {
        LinearGradient(
            colors: [.white.opacity(0.16), .clear],
            startPoint: .topLeading, endPoint: .init(x: 0.34, y: 0.34)
        )
    }

    @ViewBuilder private var sceneLayer: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color(hex: 0x2A3A49)
        }
    }
}
