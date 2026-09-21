import CoreData

/// Owns the `NSPersistentContainer`. This is the only place business logic
/// may treat Core Data as a singleton — repositories receive the container
/// through initializers rather than reaching for `.shared` themselves.
final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    static var preview: PersistenceController {
        PersistenceController(inMemory: true)
    }

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Pawlease")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
