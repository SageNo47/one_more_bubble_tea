import Foundation

public struct ReminderSettings: Codable, Hashable, Sendable {
    public var hour: Int
    public var minute: Int
    public var second: Int
    public var message: String
    public var selectedMilkTeaID: MilkTea.ID

    public init(
        hour: Int,
        minute: Int,
        second: Int,
        message: String,
        selectedMilkTeaID: MilkTea.ID
    ) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.message = message
        self.selectedMilkTeaID = selectedMilkTeaID
    }

    public static let standard = ReminderSettings(
        hour: 15,
        minute: 0,
        second: 0,
        message: "今天要不要来一杯奶茶呀？🧋",
        selectedMilkTeaID: MilkTea.brownSugar.id
    )

    public var timeComponents: DateComponents {
        DateComponents(hour: hour, minute: minute, second: second)
    }
}
