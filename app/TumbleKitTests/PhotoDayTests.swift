import Testing
import Foundation
@testable import TumbleKit

struct PhotoDayTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func groupsMixedDailyCountsNewestDayFirst() {
        let now = date(day: 5, hour: 18)
        let all = photos(count: 7, on: date(day: 1))
            + photos(count: 9, on: date(day: 2))
            + photos(count: 12, on: date(day: 3))
            + photos(count: 60, on: date(day: 4))
            + photos(count: 72, on: date(day: 5))

        let days = PhotoDay.group(all, calendar: calendar, now: now)

        #expect(days.map(\.totalCount) == [72, 60, 12, 9, 7])
        #expect(days.first?.displayTitle == "Today")
        #expect(days.dropFirst().first?.displayTitle == "Yesterday")
    }

    @Test func sortsPhotosNewestFirstInsideEachDay() {
        let morning = Photo(capturedAt: date(day: 1, hour: 8))
        let afternoon = Photo(capturedAt: date(day: 1, hour: 15))
        let night = Photo(capturedAt: date(day: 1, hour: 22))

        let day = PhotoDay.group([afternoon, morning, night], calendar: calendar, now: date(day: 2)).first

        #expect(day?.photos.map(\.id) == [night.id, afternoon.id, morning.id])
    }

    @Test func countsDevelopedPhotos() {
        let dayPhotos = photos(count: 12, on: date(day: 1), developed: 5)
        let day = PhotoDay.group(dayPhotos, calendar: calendar, now: date(day: 1)).first

        #expect(day?.totalCount == 12)
        #expect(day?.developedCount == 5)
    }

    private func photos(count: Int, on base: Date, developed: Int = 0) -> [Photo] {
        (0..<count).map { index in
            let photo = Photo(capturedAt: base.addingTimeInterval(Double(index) * 60))
            photo.isDeveloped = index < developed
            photo.developProgress = photo.isDeveloped ? 1 : 0
            return photo
        }
    }

    private func date(day: Int, hour: Int = 12) -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: 2026,
                month: 7,
                day: day,
                hour: hour
            )
        )!
    }
}
