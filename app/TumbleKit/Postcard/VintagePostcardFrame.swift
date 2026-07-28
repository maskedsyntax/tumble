import SwiftUI
import UIKit

/// A vintage postcard back: "POST CARD" letterpress header, a stamp box with
/// a wavy postmark ring carrying the capture date, a divider, and the note in
/// handwriting on the writing side.
struct VintagePostcardFrame: View {
    let image: UIImage?
    let age: Double
    let note: String?
    let capturedAt: Date
    let width: CGFloat

    private var ink: Color { Palette.ink }

    var body: some View {
        VStack(spacing: 0) {
            PostcardPhoto(image: image, age: age, width: width)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: width * 0.008))
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.008)
                        .strokeBorder(ink.opacity(0.18), lineWidth: 0.5)
                )
                .padding(width * 0.05)
                .padding(.bottom, width * 0.02)

            postcardBack
                .frame(height: width * 0.34)
                .padding(.horizontal, width * 0.06)
                .padding(.bottom, width * 0.055)
        }
        .frame(width: width)
        .background(Palette.printStock)
        .clipShape(RoundedRectangle(cornerRadius: width * 0.02))
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.02)
                .strokeBorder(ink.opacity(0.1), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.45), radius: width * 0.05, x: 0, y: width * 0.04)
    }

    private var postcardBack: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(ink.opacity(0.28))
                .frame(height: 0.75)
                .padding(.top, width * 0.016)
            noteArea
                .padding(.top, width * 0.02)
            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: width * 0.04) {
            VStack(alignment: .leading, spacing: width * 0.006) {
                Text("POST CARD")
                    .font(Typography.display(width * 0.042, weight: .semibold))
                    .tracking(width * 0.008)
                    .foregroundStyle(ink.opacity(0.72))
                Text("Correspondence")
                    .font(Typography.sans(width * 0.02))
                    .tracking(width * 0.002)
                    .foregroundStyle(ink.opacity(0.42))
            }
            .padding(.top, width * 0.01)

            Spacer(minLength: 0)

            stampAndPostmark
        }
    }

    private var stampAndPostmark: some View {
        ZStack(alignment: .topTrailing) {
            stampBox
                .padding(.top, width * 0.012)
            postmark
                .offset(x: -width * 0.045, y: -width * 0.014)
        }
    }

    private var stampBox: some View {
        Rectangle()
            .fill(Color.white.opacity(0.5))
            .frame(width: width * 0.15, height: width * 0.115)
            .overlay(
                Rectangle()
                    .strokeBorder(ink.opacity(0.35), style: StrokeStyle(lineWidth: 0.75, dash: [width * 0.008, width * 0.005]))
            )
            .overlay(
                Image(systemName: "camera.aperture")
                    .font(.system(size: width * 0.035, weight: .light))
                    .foregroundStyle(Palette.amber.opacity(0.8))
            )
    }

    private var postmark: some View {
        ZStack {
            Circle()
                .strokeBorder(ink.opacity(0.4), lineWidth: 1)
                .frame(width: width * 0.115, height: width * 0.115)
            Circle()
                .strokeBorder(ink.opacity(0.3), lineWidth: 0.5)
                .frame(width: width * 0.088, height: width * 0.088)
            Text(capturedAt, format: .dateTime.day(.twoDigits).month(.abbreviated).year())
                .font(.system(size: width * 0.017, weight: .semibold, design: .monospaced))
                .textCase(.uppercase)
                .foregroundStyle(ink.opacity(0.55))
        }
        .rotationEffect(.degrees(-9))
    }

    private var noteArea: some View {
        HStack(spacing: 0) {
            Text(note?.isEmpty == false ? note! : "Wish you were here.")
                .font(Typography.script(width * 0.052))
                .foregroundStyle(ink.opacity(note?.isEmpty == false ? 0.78 : 0.3))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: width * 0.6, alignment: .leading)
            Spacer(minLength: 0)
        }
    }
}
