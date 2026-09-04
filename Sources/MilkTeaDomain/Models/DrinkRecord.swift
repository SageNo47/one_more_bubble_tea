import Foundation

public enum DrinkSource: String, Codable, Hashable, Sendable {
    case reminder
    case manual
}

public struct DrinkRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let day: LocalDay
    public let createdAt: Date
    public let milkTeaID: String?
    public let source: DrinkSource

    public init(
        id: UUID = UUID(),
        day: LocalDay,
        createdAt: Date = Date(),
        milkTeaID: String?,
        source: DrinkSource
    ) {
        self.id = id
        self.day = day
        self.createdAt = createdAt
        self.milkTeaID = milkTeaID
        self.source = source
    }
}
