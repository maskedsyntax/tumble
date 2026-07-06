import Testing
import SwiftUI
@testable import TumbleKit

struct ThemeTests {
    @Test func paletteHexDecodes() {
        // 0xDFAB68 -> (223, 171, 104)
        let c = Color(hex: 0xDFAB68)
        let resolved = c.resolve(in: EnvironmentValues())
        #expect(abs(resolved.red - 223.0 / 255) < 0.01)
        #expect(abs(resolved.green - 171.0 / 255) < 0.01)
        #expect(abs(resolved.blue - 104.0 / 255) < 0.01)
    }
}
