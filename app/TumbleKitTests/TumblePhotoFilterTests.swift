import Testing
import UIKit
@testable import TumbleKit

struct TumblePhotoFilterTests {
    @Test @MainActor func rendersApprovedMemoryPresets() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 48)).image { context in
            UIColor(red: 0.18, green: 0.32, blue: 0.58, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 80, height: 48))
            UIColor(red: 0.95, green: 0.72, blue: 0.34, alpha: 1).setFill()
            context.fill(CGRect(x: 18, y: 12, width: 44, height: 24))
        }
        let source = image.jpegData(compressionQuality: 0.92)!

        for preset in TumbleMemoryFilterPreset.allCases {
            let output = TumblePhotoFilter.renderMemoryPhotoData(from: source, preset: preset)
            #expect(output != nil)
            let rendered = output.flatMap(UIImage.init(data:))
            #expect(rendered != nil)
            if let rendered {
                #expect(abs((rendered.size.width / rendered.size.height) - (image.size.width / image.size.height)) < 0.01)
            }
        }
    }

    @Test @MainActor func presetsLookDistinct() throws {
        let size = CGSize(width: 600, height: 600)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(red: 0.55, green: 0.72, blue: 0.88, alpha: 1).cgColor,
                          UIColor(red: 0.20, green: 0.35, blue: 0.45, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            UIColor(red: 0.85, green: 0.35, blue: 0.30, alpha: 1).setFill()
            ctx.cgContext.fill(CGRect(x: 60, y: 380, width: 180, height: 180))
            UIColor(red: 0.95, green: 0.80, blue: 0.45, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 380, y: 120, width: 140, height: 140))
            UIColor(red: 0.30, green: 0.55, blue: 0.35, alpha: 1).setFill()
            ctx.cgContext.fill(CGRect(x: 360, y: 400, width: 180, height: 160))
        }
        let source = image.jpegData(compressionQuality: 0.92)!

        var outputs: [Data] = []
        for preset in TumbleMemoryFilterPreset.allCases {
            let output = TumblePhotoFilter.renderMemoryPhotoData(from: source, preset: preset)
            #expect(output != nil)
            if let output {
                outputs.append(output)
                try output.write(to: URL(fileURLWithPath: "/tmp/tumble-filter-\(preset.rawValue).jpg"))
            }
        }
        // The two presets must produce visibly different pixels.
        #expect(Set(outputs.map(\.hashValue)).count == TumbleMemoryFilterPreset.allCases.count)
    }
}
