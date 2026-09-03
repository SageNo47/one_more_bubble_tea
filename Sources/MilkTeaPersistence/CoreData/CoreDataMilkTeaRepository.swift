import CoreData
import Foundation
import MilkTeaDomain

public final class CoreDataMilkTeaRepository: MilkTeaRepository {
    private let context: NSManagedObjectContext

    public init(container: NSPersistentContainer) {
        context = container.viewContext
    }

    public func fetchAll() throws -> [MilkTea] {
        var result: Result<[MilkTea], Error>!
        context.performAndWait {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: "MilkTeaEntity")
                request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                var objects = try context.fetch(request)

                if !objects.contains(where: { $0.value(forKey: "id") as? String == MilkTea.brownSugar.id }) {
                    objects.append(insert(MilkTea.brownSugar))
                    try context.save()
                }

                result = .success(objects.compactMap(mapToDomain))
            } catch {
                context.rollback()
                result = .failure(error)
            }
        }
        return try result.get()
    }

    private func insert(_ milkTea: MilkTea) -> NSManagedObject {
        let object = NSEntityDescription.insertNewObject(
            forEntityName: "MilkTeaEntity",
            into: context
        )
        object.setValue(milkTea.id, forKey: "id")
        object.setValue(milkTea.name, forKey: "name")
        object.setValue(milkTea.artworkAssetName, forKey: "artworkAssetName")
        object.setValue(milkTea.stickerAssetName, forKey: "stickerAssetName")
        object.setValue(Int64(milkTea.priceMinorUnits), forKey: "priceMinorUnits")
        object.setValue(milkTea.currencyCode, forKey: "currencyCode")
        object.setValue(milkTea.description, forKey: "details")
        object.setValue(milkTea.displayConfiguration.scale, forKey: "displayScale")
        object.setValue(milkTea.displayConfiguration.offsetX, forKey: "displayOffsetX")
        object.setValue(milkTea.displayConfiguration.offsetY, forKey: "displayOffsetY")
        return object
    }

    private func mapToDomain(_ object: NSManagedObject) -> MilkTea? {
        guard let id = object.value(forKey: "id") as? String,
              let name = object.value(forKey: "name") as? String,
              let artworkAssetName = object.value(forKey: "artworkAssetName") as? String,
              let currencyCode = object.value(forKey: "currencyCode") as? String,
              let details = object.value(forKey: "details") as? String else {
            return nil
        }

        return MilkTea(
            id: id,
            name: name,
            artworkAssetName: artworkAssetName,
            stickerAssetName: object.value(forKey: "stickerAssetName") as? String,
            priceMinorUnits: Int(object.value(forKey: "priceMinorUnits") as? Int64 ?? 0),
            currencyCode: currencyCode,
            description: details,
            displayConfiguration: MilkTeaDisplayConfiguration(
                scale: object.value(forKey: "displayScale") as? Double ?? 1,
                offsetX: object.value(forKey: "displayOffsetX") as? Double ?? 0,
                offsetY: object.value(forKey: "displayOffsetY") as? Double ?? 0
            )
        )
    }
}
