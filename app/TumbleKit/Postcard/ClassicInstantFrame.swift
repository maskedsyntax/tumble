import SwiftUI
import UIKit

/// The Tumble print itself as a postcard: cream stock, thick chin, the note
/// in script, and a small capture date burnt into the chin's trailing edge.
struct ClassicInstantFrame: View {
    let image: UIImage?
    let age: Double
    let note: String?
    let capturedAt: Date
    let width: CGFloat

    var body: some View {
        PrintView(
            image: image,
            isDeveloped: true,
            developProgress: 1,
            age: age,
            caption: note,
            width: width
        )
        .overlay(alignment: .bottomTrailing) {
            Text(capturedAt, format: .dateTime.day(.twoDigits).month(.abbreviated).year(.twoDigits))
                .font(.system(size: width * 0.024, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.ink.opacity(0.38))
                .padding(.trailing, width * 0.075)
                .padding(.bottom, width * 0.045)
        }
    }
}
