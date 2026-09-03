import MilkTeaDomain
import XCTest
@testable import MilkTeaPet

@MainActor
final class MilkTeaStoreTests: XCTestCase {
    func testLoadsSelectionWithoutWritingSettings() {
        let settings = SettingsRepositorySpy()
        settings.stored = ReminderSettings(
            hour: 15,
            minute: 0,
            second: 0,
            message: "提醒",
            selectedMilkTeaID: MilkTea.brownSugar.id
        )
        let repository = MilkTeaRepositoryStub(milkTeas: [.brownSugar])

        let store = MilkTeaStore(
            milkTeaRepository: repository,
            settingsRepository: settings
        )

        XCTAssertEqual(store.selectedMilkTea, .brownSugar)
        XCTAssertEqual(settings.saveCallCount, 0)
    }
}

private final class MilkTeaRepositoryStub: MilkTeaRepository {
    let milkTeas: [MilkTea]

    init(milkTeas: [MilkTea]) {
        self.milkTeas = milkTeas
    }

    func fetchAll() throws -> [MilkTea] {
        milkTeas
    }
}

private final class SettingsRepositorySpy: SettingsRepository {
    var stored = ReminderSettings.standard
    var saveCallCount = 0

    func load() -> ReminderSettings {
        stored
    }

    func save(_ settings: ReminderSettings) {
        stored = settings
        saveCallCount += 1
    }
}
