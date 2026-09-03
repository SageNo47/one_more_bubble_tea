import Combine
import Foundation
import MilkTeaDomain

@MainActor
final class MilkTeaStore: ObservableObject {
    @Published private(set) var milkTeas: [MilkTea]
    @Published var selectedMilkTeaID: MilkTea.ID

    var selectedMilkTea: MilkTea {
        milkTeas.first(where: { $0.id == selectedMilkTeaID }) ?? .brownSugar
    }

    init(
        milkTeaRepository: any MilkTeaRepository,
        settingsRepository: any SettingsRepository
    ) {
        let loadedMilkTeas: [MilkTea]
        do {
            let repositoryMilkTeas = try milkTeaRepository.fetchAll()
            loadedMilkTeas = repositoryMilkTeas.isEmpty ? [.brownSugar] : repositoryMilkTeas
        } catch {
            loadedMilkTeas = [.brownSugar]
        }

        let savedID = settingsRepository.load().selectedMilkTeaID
        milkTeas = loadedMilkTeas
        selectedMilkTeaID = loadedMilkTeas.contains(where: { $0.id == savedID })
            ? savedID
            : loadedMilkTeas[0].id
    }
}
