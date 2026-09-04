import Foundation
import MilkTeaDomain
import XCTest
@testable import MilkTeaPersistence

final class CoreDataDrinkRecordRepositoryTests: XCTestCase {
    func testAddsFetchesAndDeletesIndividualRecords() throws {
        let stack = try CoreDataStack(inMemory: true)
        let repository = CoreDataDrinkRecordRepository(container: stack.container)
        let first = DrinkRecord(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            day: LocalDay(year: 2026, month: 9, day: 3),
            createdAt: Date(timeIntervalSince1970: 100),
            milkTeaID: "brown-sugar-boba",
            source: .reminder
        )
        let second = DrinkRecord(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            day: LocalDay(year: 2026, month: 9, day: 3),
            createdAt: Date(timeIntervalSince1970: 200),
            milkTeaID: nil,
            source: .manual
        )

        try repository.add(first)
        try repository.add(second)

        XCTAssertEqual(try repository.fetchAll(), [first, second])
        XCTAssertEqual(
            try repository.fetch(in: LocalDay(year: 2026, month: 9, day: 3)...LocalDay(year: 2026, month: 9, day: 3)),
            [first, second]
        )

        try repository.delete(id: first.id)
        XCTAssertEqual(try repository.fetchAll(), [second])
    }

    func testDeletingMissingRecordIsHarmless() throws {
        let stack = try CoreDataStack(inMemory: true)
        let repository = CoreDataDrinkRecordRepository(container: stack.container)

        XCTAssertNoThrow(try repository.delete(id: UUID()))
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }
}
