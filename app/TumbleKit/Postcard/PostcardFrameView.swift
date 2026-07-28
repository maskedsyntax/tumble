import SwiftUI
import UIKit

/// A developed photo mounted in one of the postcard frames, ready for
/// on-screen preview or offscreen `ImageRenderer` export. All frames share
/// the same aged photo treatment as the in-app print.
public struct PostcardFrameView: View {
    private let style: PostcardFrameStyle
    private let image: UIImage?
    private let age: Double
    private let note: String?
    private let capturedAt: Date
    private let seed: UInt64
    private let width: CGFloat

    public init(
        style: PostcardFrameStyle,
        image: UIImage?,
        age: Double = 0,
        note: String? = nil,
        capturedAt: Date = Date(),
        seed: UInt64 = 0,
        width: CGFloat = 1280
    ) {
        self.style = style
        self.image = image
        self.age = age
        self.note = note
        self.capturedAt = capturedAt
        self.seed = seed
        self.width = width
    }

    public init(
        style: PostcardFrameStyle,
        image: UIImage?,
        photo: Photo,
        width: CGFloat = 1280
    ) {
        self.init(
            style: style,
            image: image,
            age: photo.ageFraction(),
            note: photo.caption,
            capturedAt: photo.capturedAt,
            seed: photo.id.stableSeed,
            width: width
        )
    }

    public var body: some View {
        Group {
            switch style {
            case .none:
                PostcardPhoto(image: image, age: age, width: width)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: width * 0.01))
                    .overlay(
                        RoundedRectangle(cornerRadius: width * 0.01)
                            .strokeBorder(.black.opacity(0.15), lineWidth: 0.5)
                    )
            case .classicInstant:
                ClassicInstantFrame(image: image, age: age, note: note, capturedAt: capturedAt, width: width)
            case .vintagePostcard:
                VintagePostcardFrame(image: image, age: age, note: note, capturedAt: capturedAt, width: width)
            case .borderedFilm:
                BorderedFilmFrame(image: image, age: age, note: note, capturedAt: capturedAt, width: width)
            case .deckledEdge:
                DeckledEdgeFrame(image: image, age: age, note: note, seed: seed, width: width)
            }
        }
        .frame(width: width)
    }
}

/// The developed-photo treatment shared by every frame: the scene, the warm
/// aged grade that grows with age, film grain, a vignette, and a soft sheen -
/// the same recipe as the in-app `PrintView`.
struct PostcardPhoto: View {
    let image: UIImage?
    let age: Double
    let width: CGFloat

    var body: some View {
        ZStack {
            sceneLayer
            agedGrade
            GrainOverlay(opacity: 0.4)
            vignette
            sheen
        }
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
}

public extension UUID {
    /// A deterministic 64-bit seed folded from the UUID bytes (Swift's
    /// `hashValue` is per-process, so it can't anchor stable print details).
    var stableSeed: UInt64 {
        var value: UInt64 = 0x9E3779B97F4A7C15
        let bytes = Mirror(reflecting: uuid).children.map { $0.value as? UInt8 ?? 0 }
        for byte in bytes {
            value = (value ^ UInt64(byte)) &* 0x100000001B3
        }
        return value
    }
}

/// A tiny deterministic PRNG (SplitMix64) for procedural frame details.
struct StableRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
