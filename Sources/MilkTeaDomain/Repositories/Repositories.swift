import Foundation

public protocol SettingsRepository: AnyObject {
    func load() -> ReminderSettings
    func save(_ settings: ReminderSettings)
}

public protocol MilkTeaRepository: AnyObject {
    func fetchAll() throws -> [MilkTea]
}

public protocol DrinkRecordRepository: AnyObject {
    func fetchAll() throws -> [DrinkRecord]
    func fetch(in dayRange: ClosedRange<LocalDay>) throws -> [DrinkRecord]
    func add(_ record: DrinkRecord) throws
    func delete(id: UUID) throws
}
