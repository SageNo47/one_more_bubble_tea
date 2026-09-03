import Foundation
import XCTest
@testable import MilkTeaDomain

final class ReminderScheduleCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testSchedulesLaterTimeOnSameDay() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 3, hour: 14, minute: 0, second: 0
        )))
        let expected = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 3, hour: 15, minute: 0, second: 0
        )))

        let result = ReminderScheduleCalculator.nextFireDate(
            after: now,
            target: DateComponents(hour: 15, minute: 0, second: 0),
            calendar: calendar
        )

        XCTAssertEqual(result, expected)
    }

    func testSchedulesNextDayWhenTimeHasAlreadyPassed() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 3, hour: 16, minute: 0, second: 0
        )))
        let expected = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 4, hour: 15, minute: 0, second: 0
        )))

        let result = ReminderScheduleCalculator.nextFireDate(
            after: now,
            target: DateComponents(hour: 15, minute: 0, second: 0),
            calendar: calendar
        )

        XCTAssertEqual(result, expected)
    }

    func testRejectsInvalidTime() {
        let result = ReminderScheduleCalculator.nextFireDate(
            after: Date(),
            target: DateComponents(hour: 25, minute: 0, second: 0),
            calendar: calendar
        )

        XCTAssertNil(result)
    }
}
