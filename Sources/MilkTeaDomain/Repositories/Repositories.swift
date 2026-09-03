import Foundation

public protocol SettingsRepository: AnyObject {
    func load() -> ReminderSettings
    func save(_ settings: ReminderSettings)
}

public protocol MilkTeaRepository: AnyObject {
    func fetchAll() throws -> [MilkTea]
}
