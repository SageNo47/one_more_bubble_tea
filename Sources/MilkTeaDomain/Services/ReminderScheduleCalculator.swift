import Foundation

public enum ReminderScheduleCalculator {
    public static func nextFireDate(
        after date: Date,
        target: DateComponents,
        calendar: Calendar
    ) -> Date? {
        guard let hour = target.hour, (0...23).contains(hour),
              let minute = target.minute, (0...59).contains(minute),
              let second = target.second, (0...59).contains(second) else {
            return nil
        }

        return calendar.nextDate(
            after: date,
            matching: DateComponents(hour: hour, minute: minute, second: second),
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }
}
