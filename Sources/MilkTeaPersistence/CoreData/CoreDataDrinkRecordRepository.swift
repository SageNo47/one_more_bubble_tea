import CoreData
import Foundation
import MilkTeaDomain

public final class CoreDataDrinkRecordRepository: DrinkRecordRepository {
    private let context: NSManagedObjectContext

    public init(container: NSPersistentContainer) {
        context = container.viewContext
    }

    public func fetchAll() throws -> [DrinkRecord] {
        try fetch(predicate: nil)
    }

    public func fetch(in dayRange: ClosedRange<LocalDay>) throws -> [DrinkRecord] {
        try fetch(predicate: NSPredicate(
            format: "dayValue >= %lld AND dayValue <= %lld",
            Int64(dayRange.lowerBound.sortableValue),
            Int64(dayRange.upperBound.sortableValue)
        ))
    }

    public func add(_ record: DrinkRecord) throws {
        var result: Result<Void, Error>!
        context.performAndWait {
            do {
                let object = NSEntityDescription.insertNewObject(
                    forEntityName: "DrinkRecordEntity",
                    into: context
                )
                object.setValue(record.id, forKey: "id")
                object.setValue(Int64(record.day.sortableValue), forKey: "dayValue")
                object.setValue(Int32(record.day.year), forKey: "dayYear")
                object.setValue(Int16(record.day.month), forKey: "dayMonth")
                object.setValue(Int16(record.day.day), forKey: "dayDay")
                object.setValue(record.createdAt, forKey: "createdAt")
                object.setValue(record.milkTeaID, forKey: "milkTeaID")
                object.setValue(record.source.rawValue, forKey: "source")
                try context.save()
                result = .success(())
            } catch {
                context.rollback()
                result = .failure(error)
            }
        }
        return try result.get()
    }

    public func delete(id: UUID) throws {
        var result: Result<Void, Error>!
        context.performAndWait {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: "DrinkRecordEntity")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                if let object = try context.fetch(request).first {
                    context.delete(object)
                    try context.save()
                }
                result = .success(())
            } catch {
                context.rollback()
                result = .failure(error)
            }
        }
        return try result.get()
    }

    private func fetch(predicate: NSPredicate?) throws -> [DrinkRecord] {
        var result: Result<[DrinkRecord], Error>!
        context.performAndWait {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: "DrinkRecordEntity")
                request.predicate = predicate
                request.sortDescriptors = [
                    NSSortDescriptor(key: "dayValue", ascending: true),
                    NSSortDescriptor(key: "createdAt", ascending: true),
                    NSSortDescriptor(key: "id", ascending: true)
                ]
                result = .success(try context.fetch(request).compactMap(mapToDomain))
            } catch {
                result = .failure(error)
            }
        }
        return try result.get()
    }

    private func mapToDomain(_ object: NSManagedObject) -> DrinkRecord? {
        guard let id = object.value(forKey: "id") as? UUID,
              let createdAt = object.value(forKey: "createdAt") as? Date,
              let sourceValue = object.value(forKey: "source") as? String,
              let source = DrinkSource(rawValue: sourceValue) else {
            return nil
        }

        let year = (object.value(forKey: "dayYear") as? NSNumber)?.intValue ?? 0
        let month = (object.value(forKey: "dayMonth") as? NSNumber)?.intValue ?? 0
        let day = (object.value(forKey: "dayDay") as? NSNumber)?.intValue ?? 0
        return DrinkRecord(
            id: id,
            day: LocalDay(year: year, month: month, day: day),
            createdAt: createdAt,
            milkTeaID: object.value(forKey: "milkTeaID") as? String,
            source: source
        )
    }
}
