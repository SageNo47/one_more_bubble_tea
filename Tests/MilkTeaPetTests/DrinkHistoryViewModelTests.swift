import Foundation
import MilkTeaDomain
import XCTest
@testable import MilkTeaPet

@MainActor
final class DrinkHistoryViewModelTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    func testSeptemberGridStartsOnMondayAndKeepsSundayStylingDataNeutral() throws {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.calendarDays.count, 35)
        XCTAssertEqual(viewModel.calendarDays.first?.day, LocalDay(year: 2026, month: 8, day: 31))
        XCTAssertEqual(viewModel.calendarDays[6].day, LocalDay(year: 2026, month: 9, day: 6))
    }

    func testManualAddUpdatesDayWeekAndMonthCounts() {
        let repository = DrinkRecordRepositoryStub()
        let viewModel = makeViewModel(repository: repository)
        viewModel.load()

        XCTAssertTrue(viewModel.addDrink())
        XCTAssertEqual(viewModel.selectedDayRecords.count, 1)
        XCTAssertEqual(viewModel.weekCount, 1)
        XCTAssertEqual(viewModel.monthCount, 1)
        XCTAssertEqual(repository.records.first?.source, .manual)
        XCTAssertEqual(repository.records.first?.milkTeaID, MilkTea.brownSugar.id)
    }

    func testCannotAddForFutureDay() {
        let repository = DrinkRecordRepositoryStub()
        let viewModel = makeViewModel(repository: repository)
        viewModel.select(LocalDay(year: 2026, month: 9, day: 4))

        XCTAssertFalse(viewModel.canAddSelectedDay)
        XCTAssertFalse(viewModel.addDrink())
        XCTAssertTrue(repository.records.isEmpty)
    }

    func testDeletesOnlySelectedRecord() {
        let first = DrinkRecord(
            day: LocalDay(year: 2026, month: 9, day: 3),
            milkTeaID: nil,
            source: .manual
        )
        let second = DrinkRecord(
            day: LocalDay(year: 2026, month: 9, day: 3),
            milkTeaID: nil,
            source: .reminder
        )
        let repository = DrinkRecordRepositoryStub(records: [first, second])
        let viewModel = makeViewModel(repository: repository)
        viewModel.load()

        viewModel.delete(first)

        XCTAssertEqual(viewModel.selectedDayRecords, [second])
        XCTAssertEqual(repository.records, [second])
    }

    private func makeViewModel(
        repository: DrinkRecordRepositoryStub = DrinkRecordRepositoryStub()
    ) -> DrinkHistoryViewModel {
        let fixedNow = calendar.date(from: DateComponents(
            year: 2026, month: 9, day: 3, hour: 15, minute: 20
        ))!
        return DrinkHistoryViewModel(
            repository: repository,
            milkTeaID: { MilkTea.brownSugar.id },
            calendar: calendar,
            now: { fixedNow }
        )
    }
}

private final class DrinkRecordRepositoryStub: DrinkRecordRepository {
    var records: [DrinkRecord]

    init(records: [DrinkRecord] = []) {
        self.records = records
    }

    func fetchAll() throws -> [DrinkRecord] {
        records
    }

    func fetch(in dayRange: ClosedRange<LocalDay>) throws -> [DrinkRecord] {
        records.filter { dayRange.contains($0.day) }
    }

    func add(_ record: DrinkRecord) throws {
        records.append(record)
    }

    func delete(id: UUID) throws {
        records.removeAll { $0.id == id }
    }
}
