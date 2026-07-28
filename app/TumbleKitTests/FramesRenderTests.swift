import Testing
import SwiftUI
import UIKit
@testable import TumbleKit

struct FramesRenderTests {
    @MainActor
    @Test func everyFrameRenders() throws {
        let image = sampleImage()
        let note = "Golden hour at the pier, take me back"

        for style in PostcardFrameStyle.allCases {
            let view = PostcardFrameView(
                style: style,
                image: image,
                age: 0.4,
                note: note,
                capturedAt: Date(timeIntervalSince1970: 1_750_000_000),
                seed: 12345,
                width: 800
            )
            .padding(60)
            .background(Color.white)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            let rendered = renderer.uiImage
            #expect(rendered != nil, "\(style) did not render")

            if let data = rendered?.pngData() {
                let url = URL(fileURLWithPath: "/tmp/tumble-frame-\(style.rawValue).png")
                try data.write(to: url)
            }
        }
    }

    private func sampleImage() -> UIImage {
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [UIColor(red: 0.85, green: 0.62, blue: 0.42, alpha: 1).cgColor,
                          UIColor(red: 0.24, green: 0.34, blue: 0.44, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            // Sun
            ctx.cgContext.setFillColor(UIColor(red: 0.98, green: 0.85, blue: 0.6, alpha: 1).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 480, y: 420, width: 140, height: 140))
            // Horizon
            ctx.cgContext.setFillColor(UIColor(red: 0.16, green: 0.24, blue: 0.3, alpha: 1).cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 560, width: size.width, height: 240))
        }
    }
}
