import AppKit

@MainActor
final class AppCoordinator {
    private let dependencies: AppDependencies
    private let reminderWindowController = ReminderWindowController()
    private let recordEffectWindowController = RecordEffectWindowController()
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

    private func showReminder(message: String?) {
        guard let petWindow = petWindowController?.panel else { return }
        reminderWindowController.show(
            relativeTo: petWindow,
            message: message ?? dependencies.settingsRepository.load().message,
            onAccept: { [weak self, weak petWindow] in
                guard let self, let petWindow else { return }
                self.recordEffectWindowController.show(relativeTo: petWindow)
            },
            onDecline: {}
        )
    }
}
