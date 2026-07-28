import SwiftUI
import UIKit

/// A photo with a hand-torn paper edge, taped to a cream album page by two
/// translucent tape strips. The tear is procedural and seeded per print, so
/// every deckle is unique but stable across renders.
struct DeckledEdgeFrame: View {
    let image: UIImage?
    let age: Double
    let note: String?
    let seed: UInt64
    let width: CGFloat

    private var photoSide: CGFloat { width * 0.82 }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                PostcardPhoto(image: image, age: age, width: photoSide)
                    .frame(width: photoSide, height: photoSide)
                    .clipShape(DeckledEdgeShape(seed: seed, roughness: photoSide * 0.012))
                    .shadow(color: .black.opacity(0.3), radius: width * 0.02, x: 0, y: width * 0.012)

                tapeStrip
                    .rotationEffect(.degrees(-14))
                    .offset(x: -photoSide * 0.36, y: -photoSide * 0.5 + width * 0.012)
                tapeStrip
                    .rotationEffect(.degrees(11))
                    .offset(x: photoSide * 0.36, y: -photoSide * 0.5 + width * 0.012)
            }
            .rotationEffect(.degrees(-1.5))
            .padding(.top, width * 0.075)

            if let note, !note.isEmpty {
                Text(note)
                    .font(Typography.script(width * 0.055))
                    .foregroundStyle(Palette.ink.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: width * 0.8)
                    .padding(.top, width * 0.055)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, width * 0.08)
        // Fixed page height - a flexible frame (minHeight) expands to fill
        // whatever the parent offers and swallows full-screen containers.
        .frame(width: width, height: width * 1.18)
        .background(
            LinearGradient(
                colors: [Palette.printStock, Color(hex: 0xEDE2C9)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: width * 0.02))
        .shadow(color: .black.opacity(0.45), radius: width * 0.05, x: 0, y: width * 0.04)
    }

    private var tapeStrip: some View {
        RoundedRectangle(cornerRadius: width * 0.004)
            .fill(Color(hex: 0xFFFDF4, opacity: 0.42))
            .frame(width: width * 0.2, height: width * 0.055)
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.004)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.12), radius: width * 0.006, y: width * 0.003)
    }
}

/// A rectangle whose four edges wander like torn paper. Points along each
/// edge get a stable pseudo-random offset from `seed`, so the same print
/// always tears the same way.
struct DeckledEdgeShape: Shape {
    let seed: UInt64
    let roughness: CGFloat

    func path(in rect: CGRect) -> Path {
        var rng = StableRandom(seed: seed)
        var path = Path()

        let steps = 28
        var top: [CGPoint] = []
        var right: [CGPoint] = []
        var bottom: [CGPoint] = []
        var left: [CGPoint] = []

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            top.append(CGPoint(
                x: rect.minX + rect.width * t,
                y: rect.minY + offset(&rng, along: t)
            ))
            right.append(CGPoint(
                x: rect.maxX + offset(&rng, along: t),
                y: rect.minY + rect.height * t
            ))
            bottom.append(CGPoint(
                x: rect.maxX - rect.width * t,
                y: rect.maxY + offset(&rng, along: t)
            ))
            left.append(CGPoint(
                x: rect.minX + offset(&rng, along: t),
                y: rect.maxY - rect.height * t
            ))
        }

        path.move(to: top[0])
        for point in top.dropFirst() { path.addLine(to: point) }
        for point in right { path.addLine(to: point) }
        for point in bottom { path.addLine(to: point) }
        for point in left { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    /// Low-frequency wander plus fine tear jitter, both inside ±roughness.
    private func offset(_ rng: inout StableRandom, along t: CGFloat) -> CGFloat {
        let wave = sin(t * .pi * 5 + CGFloat(rng.next() % 628) / 100) * roughness * 0.45
        let jitter = (CGFloat(rng.next() % 1000) / 1000 - 0.5) * roughness
        return wave + jitter
    }
}
