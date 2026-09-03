import Foundation
import AppKit

// MARK: - 设置存储

struct ReminderSettings: Codable, Hashable {
    var hour: Int
    var minute: Int
    var second: Int
    var message: String
    var selectedMilkTeaID: MilkTea.ID
}

enum PetSettings {
    static let timeKey = "reminderTime"      // "HH:mm:ss"
    static let messageKey = "reminderMessage"
    static let selectedMilkTeaIDKey = "selectedMilkTeaID"

    static func load() -> ReminderSettings {
        let components = loadTime() ?? DateComponents(hour: 15, minute: 0, second: 0)
        return ReminderSettings(
            hour: components.hour ?? 15,
            minute: components.minute ?? 0,
            second: components.second ?? 0,
            message: loadMessage(),
            selectedMilkTeaID: loadSelectedMilkTeaID()
        )
    }

    static func save(_ settings: ReminderSettings) {
        saveTime(String(format: "%02d:%02d:%02d", settings.hour, settings.minute, settings.second))
        saveMessage(settings.message)
        saveSelectedMilkTeaID(settings.selectedMilkTeaID)
    }

    static func loadTime() -> DateComponents? {
        let value = UserDefaults.standard.string(forKey: timeKey) ?? "15:00:00"
        return timeComponents(from: value)
    }

    static func timeComponents(from value: String) -> DateComponents? {
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard (2...3).contains(parts.count),
              let hour = Int(parts[0]), (0...23).contains(hour),
              let minute = Int(parts[1]), (0...59).contains(minute) else {
            return nil
        }

        let second = parts.count == 3 ? Int(parts[2]) : 0
        guard let second, (0...59).contains(second) else { return nil }
        return DateComponents(hour: hour, minute: minute, second: second)
    }

    static func saveTime(_ s: String) {
        UserDefaults.standard.set(s, forKey: timeKey)
    }

    static func loadMessage() -> String {
        UserDefaults.standard.string(forKey: messageKey) ?? "今天要不要来一杯奶茶呀？🧋"
    }

    static func saveMessage(_ s: String) {
        UserDefaults.standard.set(s, forKey: messageKey)
    }

    static func loadSelectedMilkTeaID() -> MilkTea.ID {
        UserDefaults.standard.string(forKey: selectedMilkTeaIDKey) ?? MilkTea.brownSugar.id
    }

    static func saveSelectedMilkTeaID(_ id: MilkTea.ID) {
        UserDefaults.standard.set(id, forKey: selectedMilkTeaIDKey)
    }
}

// MARK: - 提醒调度
// 直接预约下一次目标时间；休眠、唤醒或系统时间变化时重新计算。

final class ReminderScheduler: ObservableObject {
    @Published private(set) var showReminder = false

    private var timer: Timer?
    private var defaultCenterObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private(set) var pendingMessage: String?
    private var isStarted = false

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
        guard let target = PetSettings.loadTime(),
              let fireDate = Self.nextFireDate(after: now, target: target, calendar: calendar) else {
            return
        }

        let scheduledDate = fireDate
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            self?.fire(scheduledFor: scheduledDate)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func didPresentReminder() {
        showReminder = false
        pendingMessage = nil
    }

    static func nextFireDate(
        after date: Date,
        target: DateComponents,
        calendar: Calendar
    ) -> Date? {
        guard let hour = target.hour, (0...23).contains(hour),
              let minute = target.minute, (0...59).contains(minute),
              let second = target.second, (0...59).contains(second) else {
            return nil
        }

        return calendar.nextDate(
            after: date,
            matching: DateComponents(hour: hour, minute: minute, second: second),
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }

    deinit {
        cancelTimer()
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
                self?.reschedule()
            },
            defaultCenter.addObserver(
                forName: NSNotification.Name.NSSystemTimeZoneDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reschedule()
            }
        ]

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            workspaceCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.cancelTimer()
            },
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reschedule()
            }
        ]
    }

    private func fire(scheduledFor scheduledDate: Date) {
        let now = Date()

        // 防止休眠期间错过的计时器在恢复运行后补弹旧提醒。
        let deliveryDelay = now.timeIntervalSince(scheduledDate)
        guard deliveryDelay >= 0, deliveryDelay < 60 else {
            reschedule()
            return
        }

        requestReminder(message: nil)
        reschedule()
    }

    private func requestReminder(message: String?) {
        pendingMessage = message
        showReminder = true
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}
