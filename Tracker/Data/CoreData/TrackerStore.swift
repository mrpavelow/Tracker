import Foundation
import CoreData

final class TrackerStore: NSObject {

    private let context: NSManagedObjectContext
    private let converter: TrackerConverter

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()

    // MARK: - Init

    init(context: NSManagedObjectContext, converter: TrackerConverter) {
        self.context = context
        self.converter = converter
        super.init()
        try? fetchedResultsController.performFetch()
    }

    // MARK: - Fetch

    func getAll() -> [Tracker] {
        (fetchedResultsController.fetchedObjects ?? [])
            .compactMap { converter.makeTracker(from: $0) }
    }

    // MARK: - CRUD

    func add(_ tracker: Tracker) {
        let trackerCD = TrackerCoreData(context: context)
        converter.fill(entity: trackerCD, from: tracker)
        saveContext()
    }

        private func saveContext() {
            do {
                try context.save()
            } catch {
                print("Failed to save tracker: \(error)")
            }
        }

    func delete(id: UUID) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = try context.fetch(request).first {
            context.delete(obj)
            try context.save()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {}


