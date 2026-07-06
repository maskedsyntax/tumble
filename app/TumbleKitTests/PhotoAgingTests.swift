import Testing
import Foundation
@testable import TumbleKit

struct PhotoAgingTests {
    @Test func freshPrintHasNoAge() {
        let photo = Photo(capturedAt: Date())
        #expect(photo.ageFraction(now: Date()) < 0.001)
    }

    @Test func agingReachesFullAtTheSpan() {
        let captured = Date(timeIntervalSince1970: 0)
        let photo = Photo(capturedAt: captured)
        let now = captured.addingTimeInterval(Photo.agingSpan)
        #expect(photo.ageFraction(now: now) == 1)
    }

    @Test func agingIsClampedAndMonotonic() {
        let captured = Date(timeIntervalSince1970: 0)
        let photo = Photo(capturedAt: captured)
        let half = photo.ageFraction(now: captured.addingTimeInterval(Photo.agingSpan / 2))
        let quarter = photo.ageFraction(now: captured.addingTimeInterval(Photo.agingSpan / 4))
        #expect(quarter < half)
        #expect(abs(half - 0.5) < 0.01)
        // Well past the span stays clamped at 1.
        #expect(photo.ageFraction(now: captured.addingTimeInterval(Photo.agingSpan * 5)) == 1)
    }
}
