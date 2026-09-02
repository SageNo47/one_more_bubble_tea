import Foundation
import AppKit

// MARK: - 设置存储

enum PetSettings {
    static let timeKey = "reminderTime"      // "HH:mm"
    static let messageKey = "reminderMessage"
    private static let lastReminderDateKey = "lastReminderDate"

    static func loadTime() -> DateComponents? {
        let s = UserDefaults.standard.string(forKey: timeKey) ?? "15:00"
        let parts = s.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return DateComponents(hour: h, minute: m)
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

    static func loadLastReminderDate() -> Date? {
        UserDefaults.standard.object(forKey: lastReminderDateKey) as? Date
    }

    static func saveLastReminderDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastReminderDateKey)
    }
}

// MARK: - 提醒调度
// 直接预约下一次目标时间；休眠、唤醒或系统时间变化时重新计算。

final class ReminderScheduler: ObservableObject {
    @Published private(set) var showReminder = false

    private var timer: Timer?
    private var defaultCenterObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var lastFiredDate = PetSettings.loadLastReminderDate()
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
              var fireDate = Self.nextFireDate(after: now, target: target, calendar: calendar) else {
            return
        }

        if let lastFiredDate, calendar.isDate(lastFiredDate, inSameDayAs: fireDate) {
            guard let nextDate = Self.nextFireDate(
                after: fireDate,
                target: target,
                calendar: calendar
            ) else { return }
            fireDate = nextDate
        }

        let scheduledDate = fireDate
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            self?.fire(scheduledFor: scheduledDate)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func testReminder(message: String) {
        requestReminder(message: message)
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
              let minute = target.minute, (0...59).contains(minute) else {
            return nil
        }

        return calendar.nextDate(
            after: date,
            matching: DateComponents(hour: hour, minute: minute, second: 0),
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
        var calendar = Calendar.current
        calendar.timeZone = .current

        // 防止休眠期间错过的计时器在恢复运行后补弹旧提醒。
        let deliveryDelay = now.timeIntervalSince(scheduledDate)
        guard deliveryDelay >= 0, deliveryDelay < 60,
              lastFiredDate.map({ !calendar.isDate($0, inSameDayAs: now) }) ?? true else {
            reschedule()
            return
        }

        lastFiredDate = now
        PetSettings.saveLastReminderDate(now)
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
