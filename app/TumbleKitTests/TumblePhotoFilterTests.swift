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
}
