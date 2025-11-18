import Foundation
import CoreData

final class TrackerCategoryStore {

    private let context: NSManagedObjectContext
    private let converter: TrackerConverter

    init(context: NSManagedObjectContext, converter: TrackerConverter) {
        self.context = context
        self.converter = converter
    }

    // MARK: - Fetch

    func getAll() throws -> [TrackerCategory] {
        let request = TrackerCategoryCoreData.fetchRequest()
        let objects = try context.fetch(request)

        return try objects.compactMap { coreCat in
            let trackers = (coreCat.trackers as? Set<TrackerCoreData> ?? [])
                .compactMap { converter.makeTracker(from: $0) }

            return TrackerCategory(title: coreCat.title ?? "", trackers: trackers)
        }
    }

    // MARK: - add

    func addCategory(title: String) throws -> TrackerCategoryCoreData {
        let entity = TrackerCategoryCoreData(context: context)
        entity.title = title
        try context.save()
        return entity
    }
}
