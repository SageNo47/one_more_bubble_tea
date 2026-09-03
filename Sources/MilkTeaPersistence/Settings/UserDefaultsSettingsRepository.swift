import Foundation
import MilkTeaDomain

public final class UserDefaultsSettingsRepository: SettingsRepository {
    public enum Key {
        public static let reminderTime = "reminderTime"
        public static let reminderMessage = "reminderMessage"
        public static let selectedMilkTeaID = "selectedMilkTeaID"
    }

    private let defaults: UserDefaults
    private let legacyDefaults: [UserDefaults]

    public convenience init(defaults: UserDefaults = .standard) {
        let legacy = ["MilkTeaPet", "MilkTeaPet.MilkTeaPet"]
            .compactMap(UserDefaults.init(suiteName:))
        self.init(defaults: defaults, legacyDefaults: legacy)
    }

    public init(defaults: UserDefaults, legacyDefaults: [UserDefaults]) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
    }

    public func load() -> ReminderSettings {
        let standard = ReminderSettings.standard
        let components = Self.timeComponents(
            from: string(forKey: Key.reminderTime) ?? Self.timeString(from: standard)
        ) ?? standard.timeComponents

        let settings = ReminderSettings(
            hour: components.hour ?? standard.hour,
            minute: components.minute ?? standard.minute,
            second: components.second ?? standard.second,
            message: string(forKey: Key.reminderMessage) ?? standard.message,
            selectedMilkTeaID: string(forKey: Key.selectedMilkTeaID) ?? standard.selectedMilkTeaID
        )
        migrateLoadedValuesIfNeeded(settings)
        return settings
    }

    public func save(_ settings: ReminderSettings) {
        defaults.set(Self.timeString(from: settings), forKey: Key.reminderTime)
        defaults.set(settings.message, forKey: Key.reminderMessage)
        defaults.set(settings.selectedMilkTeaID, forKey: Key.selectedMilkTeaID)
    }

    public static func timeComponents(from value: String) -> DateComponents? {
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

    private static func timeString(from settings: ReminderSettings) -> String {
        String(format: "%02d:%02d:%02d", settings.hour, settings.minute, settings.second)
    }

    private func string(forKey key: String) -> String? {
        if let value = defaults.string(forKey: key) {
            return value
        }
        return legacyDefaults.lazy.compactMap { $0.string(forKey: key) }.first
    }

    private func migrateLoadedValuesIfNeeded(_ settings: ReminderSettings) {
        guard defaults.object(forKey: Key.reminderTime) == nil
                || defaults.object(forKey: Key.reminderMessage) == nil
                || defaults.object(forKey: Key.selectedMilkTeaID) == nil else {
            return
        }
        save(settings)
    }
}
