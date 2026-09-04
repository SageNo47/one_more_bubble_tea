import Foundation
import XCTest
@testable import MilkTeaDomain

final class DrinkStatisticsCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    func testLocalDayKeepsCalendarDateComponents() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 1, day: 2, hour: 23
        )))

        XCTAssertEqual(LocalDay(date: date, calendar: calendar), LocalDay(year: 2026, month: 1, day: 2))
    }

    func testWeekRangeRunsFromMondayThroughSundayAcrossMonthBoundary() throws {
        let range = try XCTUnwrap(DrinkStatisticsCalculator.weekRange(
            containing: LocalDay(year: 2026, month: 9, day: 3),
            calendar: calendar
        ))

        XCTAssertEqual(range.lowerBound, LocalDay(year: 2026, month: 8, day: 31))
        XCTAssertEqual(range.upperBound, LocalDay(year: 2026, month: 9, day: 6))
    }

    func testCountsWeekMonthAndMultipleDrinksOnOneDay() throws {
        let records = [
            record(year: 2026, month: 8, day: 31),
            record(year: 2026, month: 9, day: 3),
            record(year: 2026, month: 9, day: 3),
            record(year: 2026, month: 9, day: 20)
        ]
        let day = LocalDay(year: 2026, month: 9, day: 3)
        let week = try XCTUnwrap(DrinkStatisticsCalculator.weekRange(containing: day, calendar: calendar))
        let month = try XCTUnwrap(DrinkStatisticsCalculator.monthRange(containing: day, calendar: calendar))

        XCTAssertEqual(DrinkStatisticsCalculator.count(records, on: day), 2)
        XCTAssertEqual(DrinkStatisticsCalculator.count(records, in: week), 3)
        XCTAssertEqual(DrinkStatisticsCalculator.count(records, in: month), 3)
    }

    private func record(year: Int, month: Int, day: Int) -> DrinkRecord {
        DrinkRecord(
            day: LocalDay(year: year, month: month, day: day),
            milkTeaID: nil,
            source: .manual
        )
    }
}
