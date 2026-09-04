import CoreData
import Foundation

public final class CoreDataStack {
    public enum StackError: Error {
        case unableToLoadStore(Error)
        case unableToMigrateStore(Error)
    }

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) throws {
        let model = Self.makeManagedObjectModel()
        let storeURL: URL
        if inMemory {
            storeURL = URL(fileURLWithPath: "/dev/null")
        } else {
            storeURL = try Self.persistentStoreURL()
            do {
                try Self.migrateStoreIfNeeded(at: storeURL, destinationModel: model)
            } catch {
                throw StackError.unableToMigrateStore(error)
            }
        }

        container = NSPersistentContainer(
            name: "MilkTeaPet",
            managedObjectModel: model
        )

        let description = NSPersistentStoreDescription()
        description.type = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.url = storeURL
        container.persistentStoreDescriptions = [description]

        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }
        semaphore.wait()

        if let loadError {
            throw StackError.unableToLoadStore(loadError)
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func persistentStoreURL() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root.appendingPathComponent("MilkTeaPet", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory.appendingPathComponent("MilkTeaPet.sqlite")
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.versionIdentifiers = ["MilkTeaPetModelV2"]

        model.entities = [makeMilkTeaEntity(), makeDrinkRecordEntity()]
        return model
    }

    private static func makeVersionOneManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.versionIdentifiers = ["MilkTeaPetModelV1"]
        model.entities = [makeMilkTeaEntity()]
        return model
    }

    private static func makeMilkTeaEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "MilkTeaEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        entity.properties = [
            attribute("id", type: .stringAttributeType, optional: false),
            attribute("name", type: .stringAttributeType, optional: false),
            attribute("artworkAssetName", type: .stringAttributeType, optional: false),
            attribute("stickerAssetName", type: .stringAttributeType, optional: true),
            attribute("priceMinorUnits", type: .integer64AttributeType, optional: false),
            attribute("currencyCode", type: .stringAttributeType, optional: false),
            attribute("details", type: .stringAttributeType, optional: false),
            attribute("displayScale", type: .doubleAttributeType, optional: false),
            attribute("displayOffsetX", type: .doubleAttributeType, optional: false),
            attribute("displayOffsetY", type: .doubleAttributeType, optional: false)
        ]
        entity.uniquenessConstraints = [["id"]]
        return entity
    }

    private static func makeDrinkRecordEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DrinkRecordEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute("id", type: .UUIDAttributeType, optional: false),
            attribute("dayValue", type: .integer64AttributeType, optional: false),
            attribute("dayYear", type: .integer32AttributeType, optional: false),
            attribute("dayMonth", type: .integer16AttributeType, optional: false),
            attribute("dayDay", type: .integer16AttributeType, optional: false),
            attribute("createdAt", type: .dateAttributeType, optional: false),
            attribute("milkTeaID", type: .stringAttributeType, optional: true),
            attribute("source", type: .stringAttributeType, optional: false)
        ]
        entity.uniquenessConstraints = [["id"]]
        return entity
    }

    private static func migrateStoreIfNeeded(
        at storeURL: URL,
        destinationModel: NSManagedObjectModel
    ) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL
        )
        guard !destinationModel.isConfiguration(
            withName: nil,
            compatibleWithStoreMetadata: metadata
        ) else {
            return
        }

        let sourceModel = makeVersionOneManagedObjectModel()
        guard sourceModel.isConfiguration(
            withName: nil,
            compatibleWithStoreMetadata: metadata
        ) else {
            return
        }

        let mappingModel = try NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: destinationModel
        )
        let manager = NSMigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel
        )
        let temporaryURL = storeURL
            .deletingLastPathComponent()
            .appendingPathComponent("MilkTeaPet-migration-\(UUID().uuidString).sqlite")
        defer {
            try? FileManager.default.removeItem(at: temporaryURL)
            try? FileManager.default.removeItem(atPath: temporaryURL.path + "-wal")
            try? FileManager.default.removeItem(atPath: temporaryURL.path + "-shm")
        }

        try manager.migrateStore(
            from: storeURL,
            sourceType: NSSQLiteStoreType,
            options: nil,
            with: mappingModel,
            toDestinationURL: temporaryURL,
            destinationType: NSSQLiteStoreType,
            destinationOptions: [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
        )

        let backupName = "MilkTeaPet-v1-\(UUID().uuidString).sqlite"
        _ = try FileManager.default.replaceItemAt(
            storeURL,
            withItemAt: temporaryURL,
            backupItemName: backupName
        )
        try? FileManager.default.removeItem(atPath: storeURL.path + "-wal")
        try? FileManager.default.removeItem(atPath: storeURL.path + "-shm")
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
