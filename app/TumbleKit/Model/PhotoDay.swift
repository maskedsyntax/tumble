import Foundation

/// A computed daily collection of prints. The photos remain stored as individual
/// SwiftData rows; this helper only shapes them for Drawer and archive screens.
public struct PhotoDay: Identifiable {
    public let dayStart: Date
    public let displayTitle: String
    public let photos: [Photo]

    public var id: Date { dayStart }
    public var totalCount: Int { photos.count }
    public var developedCount: Int { photos.filter(\.isDeveloped).count }

    public init(
        dayStart: Date,
        photos: [Photo],
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        self.dayStart = dayStart
        self.displayTitle = Self.title(for: dayStart, calendar: calendar, now: now)
        self.photos = photos.sorted { lhs, rhs in
            lhs.capturedAt > rhs.capturedAt
        }
    }

    public static func group(
        _ photos: [Photo],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [PhotoDay] {
        Dictionary(grouping: photos) { photo in
            calendar.startOfDay(for: photo.capturedAt)
        }
        .map { dayStart, photos in
            PhotoDay(dayStart: dayStart, photos: photos, calendar: calendar, now: now)
        }
        .sorted { lhs, rhs in
            lhs.dayStart > rhs.dayStart
        }
    }

    private static func title(for dayStart: Date, calendar: Calendar, now: Date) -> String {
        if calendar.isDate(dayStart, inSameDayAs: now) {
            return "Today"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(dayStart, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        return dayStart.formatted(.dateTime.month(.abbreviated).day().year())
    }
}
