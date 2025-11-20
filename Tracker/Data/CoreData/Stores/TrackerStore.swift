import CoreData
import UIKit

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private let saveContext: () -> Void
    private var frc: NSFetchedResultsController<TrackerCoreData>

    override init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        self.context = appDelegate.context
        self.saveContext = appDelegate.saveContext

        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        self.frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()

        self.frc.delegate = self
        try? frc.performFetch()
    }

    func getAll() -> [TrackerCoreData] {
        try? frc.performFetch()
        return frc.fetchedObjects ?? []
    }
    
    func addTracker(name: String,
                    emoji: String,
                    colorHex: String,
                    category: TrackerCategoryCoreData,
                    schedule: [Int]) {

        let tracker = TrackerCoreData(context: context)

        tracker.id = UUID()
        tracker.name = name
        tracker.emoji = emoji
        tracker.colorHex = colorHex
        tracker.schedule = schedule as NSArray
        tracker.category = category
        category.addToTrackers(tracker)
        print(">>> category =", category)
        print(">>> SAVING tracker:", name, emoji, colorHex, schedule)
        saveContext()
        print(">>> Saved. Objects =", getAll().count)
    }

    func delete(_ tracker: TrackerCoreData) {
        context.delete(tracker)
        saveContext()
    }

    func update(_ tracker: TrackerCoreData, newName: String) {
        tracker.name = newName
        saveContext()
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {}
