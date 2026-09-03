import Foundation
import MilkTeaDomain
import XCTest
@testable import MilkTeaPersistence

final class UserDefaultsSettingsRepositoryTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "MilkTeaPetTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testUsesStandardValuesWhenNoSettingsExist() {
        let repository = UserDefaultsSettingsRepository(
            defaults: defaults,
            legacyDefaults: []
        )

        XCTAssertEqual(repository.load(), .standard)
    }

    func testSavesAndLoadsSettings() {
        let repository = UserDefaultsSettingsRepository(
            defaults: defaults,
            legacyDefaults: []
        )
        let expected = ReminderSettings(
            hour: 9,
            minute: 8,
            second: 7,
            message: "测试提醒",
            selectedMilkTeaID: "tea-id"
        )

        repository.save(expected)

        XCTAssertEqual(repository.load(), expected)
    }

    func testReadsLegacyMinutePrecisionTime() {
        defaults.set("08:30", forKey: UserDefaultsSettingsRepository.Key.reminderTime)
        let repository = UserDefaultsSettingsRepository(
            defaults: defaults,
            legacyDefaults: []
        )

        let settings = repository.load()

        XCTAssertEqual(settings.hour, 8)
        XCTAssertEqual(settings.minute, 30)
        XCTAssertEqual(settings.second, 0)
    }
}
