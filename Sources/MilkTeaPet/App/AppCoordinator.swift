import AppKit
import MilkTeaDomain

@MainActor
final class AppCoordinator {
    private let dependencies: AppDependencies
    private let reminderWindowController = ReminderWindowController()
    private let recordEffectWindowController = RecordEffectWindowController()
    private let drinkHistoryWindowController = DrinkHistoryWindowController()
    private let settingsWindowController = SettingsWindowController()
    private var petWindowController: PetWindowController?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func start() {
        let controller = PetWindowController(
            milkTeaStore: dependencies.milkTeaStore,
            scheduler: dependencies.reminderScheduler,
            onShowSettings: { [weak self] in
                self?.showSettings()
            },
            onShowHistory: { [weak self] in
                self?.showHistory()
            },
            onShowReminder: { [weak self] message in
                self?.showReminder(message: message)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        petWindowController = controller
        controller.show()
        dependencies.reminderScheduler.start()
    }

    private func showSettings() {
        guard let petWindow = petWindowController?.panel else { return }
        settingsWindowController.show(
            relativeTo: petWindow,
            settingsRepository: dependencies.settingsRepository,
            selectedMilkTeaID: dependencies.milkTeaStore.selectedMilkTeaID,
            onSettingsSaved: { [weak self] in
                self?.dependencies.reminderScheduler.reschedule()
            }
        )
    }

    private func showHistory() {
        guard let petWindow = petWindowController?.panel else { return }
        drinkHistoryWindowController.show(
            relativeTo: petWindow,
            repository: dependencies.drinkRecordRepository,
            milkTeaStore: dependencies.milkTeaStore
        )
    }

    private func showReminder(message: String?) {
        guard let petWindow = petWindowController?.panel else { return }
        reminderWindowController.show(
            relativeTo: petWindow,
            message: message ?? dependencies.settingsRepository.load().message,
            onAccept: { [weak self, weak petWindow] in
                guard let self, let petWindow else { return }
                let createdAt = Date()
                try self.dependencies.drinkRecordRepository.add(
                    DrinkRecord(
                        day: LocalDay(date: createdAt),
                        createdAt: createdAt,
                        milkTeaID: self.dependencies.milkTeaStore.selectedMilkTeaID,
                        source: .reminder
                    )
                )
                self.drinkHistoryWindowController.reloadIfVisible()
                self.recordEffectWindowController.show(relativeTo: petWindow)
            },
            onDecline: {}
        )
    }

}
