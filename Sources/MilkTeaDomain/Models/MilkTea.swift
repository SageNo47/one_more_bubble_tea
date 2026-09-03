import Foundation

public struct MilkTeaDisplayConfiguration: Codable, Hashable, Sendable {
    public var scale: Double
    public var offsetX: Double
    public var offsetY: Double

    public init(scale: Double, offsetX: Double, offsetY: Double) {
        self.scale = scale
        self.offsetX = offsetX
        self.offsetY = offsetY
    }

    public static let standard = MilkTeaDisplayConfiguration(
        scale: 1,
        offsetX: 0,
        offsetY: 0
    )
}

public struct MilkTea: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var artworkAssetName: String
    public var stickerAssetName: String?
    public var priceMinorUnits: Int
    public var currencyCode: String
    public var description: String
    public var displayConfiguration: MilkTeaDisplayConfiguration

    public init(
        id: String,
        name: String,
        artworkAssetName: String,
        stickerAssetName: String?,
        priceMinorUnits: Int,
        currencyCode: String,
        description: String,
        displayConfiguration: MilkTeaDisplayConfiguration
    ) {
        self.id = id
        self.name = name
        self.artworkAssetName = artworkAssetName
        self.stickerAssetName = stickerAssetName
        self.priceMinorUnits = priceMinorUnits
        self.currencyCode = currencyCode
        self.description = description
        self.displayConfiguration = displayConfiguration
    }

    public static let brownSugar = MilkTea(
        id: "brown-sugar-boba",
        name: "黑糖珍珠奶茶",
        artworkAssetName: "milk-tea-pet",
        stickerAssetName: nil,
        priceMinorUnits: 0,
        currencyCode: "CNY",
        description: "",
        displayConfiguration: .standard
    )
}
