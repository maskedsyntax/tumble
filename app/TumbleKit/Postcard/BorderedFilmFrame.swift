import SwiftUI
import UIKit

/// A 90s film print: full-bleed photo in a thin white border with the
/// capture date burnt into the trailing corner in amber "LCD" digits. The
/// note sits opposite in handwriting, truncating before it ever reaches the
/// date zone.
struct BorderedFilmFrame: View {
    let image: UIImage?
    let age: Double
    let note: String?
    let capturedAt: Date
    let width: CGFloat

    var body: some View {
        PostcardPhoto(image: image, age: age, width: width)
            .frame(width: width * 0.93, height: width * 0.93 * 1.25)
            .clipped()
            .overlay(alignment: .bottom) {
                burnIn
            }
            .padding(width * 0.035)
            .padding(.bottom, width * 0.01)
            .frame(width: width)
            .background(Color(hex: 0xFBF8F1))
            .clipShape(RoundedRectangle(cornerRadius: width * 0.012))
            .shadow(color: .black.opacity(0.45), radius: width * 0.05, x: 0, y: width * 0.04)
    }

    private var burnIn: some View {
        HStack(alignment: .lastTextBaseline, spacing: width * 0.03) {
            if let note, !note.isEmpty {
                Text(note)
                    .font(Typography.script(width * 0.05))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.55), radius: width * 0.006, y: width * 0.002)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: width * 0.58, alignment: .leading)
            }
            Spacer(minLength: 0)
            Text(capturedAt, format: .dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits))
                .font(.system(size: width * 0.036, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: 0xF2A65A, opacity: 0.9))
                .shadow(color: .black.opacity(0.4), radius: width * 0.004, y: width * 0.001)
        }
        .padding(.horizontal, width * 0.04)
        .padding(.bottom, width * 0.03)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}
