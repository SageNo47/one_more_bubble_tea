import CoreData
import Foundation

public final class CoreDataStack {
    public enum StackError: Error {
        case unableToLoadStore(Error)
    }

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(
            name: "MilkTeaPet",
            managedObjectModel: Self.makeManagedObjectModel()
        )

        let description = NSPersistentStoreDescription()
        description.type = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            description.url = try Self.persistentStoreURL()
        }
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
        model.versionIdentifiers = ["MilkTeaPetModelV1"]

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

        model.entities = [entity]
        return model
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
