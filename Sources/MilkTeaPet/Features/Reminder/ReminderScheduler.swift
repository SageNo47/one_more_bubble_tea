import AppKit
import Combine
import Foundation
import MilkTeaDomain

@MainActor
final class ReminderScheduler: ObservableObject {
    @Published private(set) var showReminder = false

    private let settingsRepository: any SettingsRepository
    private var timer: Timer?
    private var defaultCenterObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private(set) var pendingMessage: String?
    private var isStarted = false

    init(settingsRepository: any SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func start() {
        guard !isStarted else {
            reschedule()
            return
        }
        isStarted = true
        observeSystemChanges()
        reschedule()
    }

    func reschedule() {
        cancelTimer()

        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = .current
        let settings = settingsRepository.load()
        guard let fireDate = ReminderScheduleCalculator.nextFireDate(
            after: now,
            target: settings.timeComponents,
            calendar: calendar
        ) else {
            return
        }

        let scheduledDate = fireDate
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fire(scheduledFor: scheduledDate)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func didPresentReminder() {
        showReminder = false
        pendingMessage = nil
    }

    deinit {
        timer?.invalidate()
        defaultCenterObservers.forEach(NotificationCenter.default.removeObserver)
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(workspaceCenter.removeObserver)
    }

    private func observeSystemChanges() {
        let defaultCenter = NotificationCenter.default
        defaultCenterObservers = [
            defaultCenter.addObserver(
                forName: NSNotification.Name.NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.reschedule() }
            },
            defaultCenter.addObserver(
                forName: NSNotification.Name.NSSystemTimeZoneDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.reschedule() }
            }
        ]

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            workspaceCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.cancelTimer() }
            },
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.reschedule() }
            }
        ]
    }

    private func fire(scheduledFor scheduledDate: Date) {
        let now = Date()
        let deliveryDelay = now.timeIntervalSince(scheduledDate)
        guard deliveryDelay >= 0, deliveryDelay < 60 else {
            reschedule()
            return
        }

        pendingMessage = nil
        showReminder = true
        reschedule()
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}
