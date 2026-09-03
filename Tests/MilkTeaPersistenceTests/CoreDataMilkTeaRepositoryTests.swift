import MilkTeaDomain
import XCTest
@testable import MilkTeaPersistence

final class CoreDataMilkTeaRepositoryTests: XCTestCase {
    func testSeedsBuiltInMilkTeaOnlyOnce() throws {
        let stack = try CoreDataStack(inMemory: true)
        let repository = CoreDataMilkTeaRepository(container: stack.container)

        let firstFetch = try repository.fetchAll()
        let secondFetch = try repository.fetchAll()

        XCTAssertEqual(firstFetch, [.brownSugar])
        XCTAssertEqual(secondFetch, [.brownSugar])
    }
}
