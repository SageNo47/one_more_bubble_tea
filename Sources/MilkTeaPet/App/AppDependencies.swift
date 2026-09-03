import MilkTeaDomain
import MilkTeaPersistence

@MainActor
final class AppDependencies {
    let coreDataStack: CoreDataStack
    let settingsRepository: any SettingsRepository
    let milkTeaRepository: any MilkTeaRepository
    let reminderScheduler: ReminderScheduler
    let milkTeaStore: MilkTeaStore

    private init(
        coreDataStack: CoreDataStack,
        settingsRepository: any SettingsRepository,
        milkTeaRepository: any MilkTeaRepository
    ) {
        self.coreDataStack = coreDataStack
        self.settingsRepository = settingsRepository
        self.milkTeaRepository = milkTeaRepository
        reminderScheduler = ReminderScheduler(settingsRepository: settingsRepository)
        milkTeaStore = MilkTeaStore(
            milkTeaRepository: milkTeaRepository,
            settingsRepository: settingsRepository
        )
    }

    static func live() throws -> AppDependencies {
        let coreDataStack = try CoreDataStack()
        let settingsRepository = UserDefaultsSettingsRepository()
        let milkTeaRepository = CoreDataMilkTeaRepository(container: coreDataStack.container)
        return AppDependencies(
            coreDataStack: coreDataStack,
            settingsRepository: settingsRepository,
            milkTeaRepository: milkTeaRepository
        )
    }
}
