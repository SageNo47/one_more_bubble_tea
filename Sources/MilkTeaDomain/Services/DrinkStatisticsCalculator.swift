import Foundation

public enum DrinkStatisticsCalculator {
    public static func count(_ records: [DrinkRecord], on day: LocalDay) -> Int {
        records.lazy.filter { $0.day == day }.count
    }

    public static func count(
        _ records: [DrinkRecord],
        in range: ClosedRange<LocalDay>
    ) -> Int {
        records.lazy.filter { range.contains($0.day) }.count
    }

    public static func weekRange(
        containing day: LocalDay,
        calendar: Calendar = .current
    ) -> ClosedRange<LocalDay>? {
        var calendar = calendar
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4

        guard let date = day.date(in: calendar),
              let interval = calendar.dateInterval(of: .weekOfYear, for: date),
              let lastDate = calendar.date(byAdding: .day, value: -1, to: interval.end) else {
            return nil
        }

        return LocalDay(date: interval.start, calendar: calendar)...LocalDay(date: lastDate, calendar: calendar)
    }

    public static func monthRange(
        containing day: LocalDay,
        calendar: Calendar = .current
    ) -> ClosedRange<LocalDay>? {
        guard let date = day.date(in: calendar),
              let interval = calendar.dateInterval(of: .month, for: date),
              let lastDate = calendar.date(byAdding: .day, value: -1, to: interval.end) else {
            return nil
        }

        return LocalDay(date: interval.start, calendar: calendar)...LocalDay(date: lastDate, calendar: calendar)
    }
}
