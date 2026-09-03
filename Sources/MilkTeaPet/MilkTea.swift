import Foundation

// MARK: - 奶茶数据模型

struct MilkTeaDisplayConfiguration: Codable, Hashable {
    var scale: Double
    var offsetX: Double
    var offsetY: Double

    static let standard = MilkTeaDisplayConfiguration(
        scale: 1,
        offsetX: 0,
        offsetY: 0
    )
}

struct MilkTea: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var artworkAssetName: String
    var stickerAssetName: String?
    var priceMinorUnits: Int
    var currencyCode: String
    var description: String
    var displayConfiguration: MilkTeaDisplayConfiguration

    static let brownSugar = MilkTea(
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

final class MilkTeaStore: ObservableObject {
    @Published private(set) var milkTeas: [MilkTea]
    @Published var selectedMilkTeaID: MilkTea.ID {
        didSet {
            PetSettings.saveSelectedMilkTeaID(selectedMilkTeaID)
        }
    }

    var selectedMilkTea: MilkTea {
        milkTeas.first(where: { $0.id == selectedMilkTeaID }) ?? .brownSugar
    }

    init(milkTeas: [MilkTea] = [.brownSugar]) {
        let availableMilkTeas = milkTeas.isEmpty ? [.brownSugar] : milkTeas
        let savedID = PetSettings.loadSelectedMilkTeaID()

        self.milkTeas = availableMilkTeas
        self.selectedMilkTeaID = availableMilkTeas.contains(where: { $0.id == savedID })
            ? savedID
            : availableMilkTeas[0].id
    }
}
