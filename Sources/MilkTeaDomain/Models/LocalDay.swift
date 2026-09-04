import Foundation

public struct LocalDay: Codable, Hashable, Sendable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 1
        month = components.month ?? 1
        day = components.day ?? 1
    }

    public func date(in calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    public var sortableValue: Int {
        year * 10_000 + month * 100 + day
    }

    public static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        lhs.sortableValue < rhs.sortableValue
    }
}
