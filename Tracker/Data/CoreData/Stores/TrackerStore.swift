import CoreData
import UIKit

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreWillChangeContent(_ store: TrackerStore)
    func trackerStoreDidChangeContent(_ store: TrackerStore,
                                      insertedSections: IndexSet,
                                      deletedSections: IndexSet,
                                      insertedItems: [IndexPath],
                                      deletedItems: [IndexPath],
                                      updatedItems: [IndexPath],
                                      movedItems: [(from: IndexPath, to: IndexPath)])
    func trackerStoreDidReloadData(_ store: TrackerStore)
}

final class TrackerStore: NSObject {

    weak var delegate: TrackerStoreDelegate?

    private var currentWeekday: Weekday?
    private var searchText: String?

    private let context: NSManagedObjectContext
    private let saveContext: () -> Void
    private var frc: NSFetchedResultsController<TrackerCoreData>

    private var insertedSections = IndexSet()
    private var deletedSections = IndexSet()
    private var insertedItems: [IndexPath] = []
    private var deletedItems: [IndexPath] = []
    private var updatedItems: [IndexPath] = []
    private var movedItems: [(from: IndexPath, to: IndexPath)] = []

    override init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.context
        self.saveContext = appDelegate.saveContext

        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        self.frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )

        super.init()

        self.frc.delegate = self
        do {
                try frc.performFetch()
                print("FRC initial count =", frc.fetchedObjects?.count ?? 0)
        } catch {
            print("Initial FRC fetch error:", error)
        }
    }

    // MARK: - Публичный API для UI
    
    func setSearchText(_ text: String?) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchText = trimmed.isEmpty ? nil : trimmed
        applyFiltersAndRefetch()
    }

    func setWeekdayFilter(_ weekday: Weekday?) {
        if let weekday {
            let bit = 1 << (weekday.rawValue - 1)
            frc.fetchRequest.predicate = NSPredicate(
                format: "scheduleMask & %d != 0",
                bit
            )
        } else {
            frc.fetchRequest.predicate = nil
        }

        do {
            try frc.performFetch()
        } catch {
            print("FRC performFetch error:", error)
        }
        currentWeekday = weekday
        applyFiltersAndRefetch()
        delegate?.trackerStoreDidReloadData(self)
    }

    func numberOfSections() -> Int {
        return frc.sections?.count ?? 0
    }

    func titleForSection(_ section: Int) -> String {
        return frc.sections?[section].name ?? ""
    }

    func numberOfItems(in section: Int) -> Int {
        return frc.sections?[section].numberOfObjects ?? 0
    }

    func tracker(at indexPath: IndexPath) -> Tracker {
        let core = frc.object(at: indexPath)
        return makeTracker(from: core)
    }

    // MARK: - CRUD

    func addTracker(name: String,
                    emoji: String,
                    colorHex: String,
                    categoryTitle: String,
                    schedule: [Int]) {

        let category = getOrCreateCategory(with: categoryTitle)

        let tracker = TrackerCoreData(context: context)
        tracker.id = UUID()
        tracker.name = name
        tracker.emoji = emoji
        tracker.colorHex = colorHex

        tracker.schedule = schedule.map { NSNumber(value: $0) } as NSArray

        let mask = schedule.reduce(0) { partial, rawValue in
            let bit = 1 << (rawValue - 1)
            return partial | bit
        }
        tracker.scheduleMask = Int16(mask)

        tracker.category = category
        category.addToTrackers(tracker)

        saveContext()
    }

    func delete(at indexPath: IndexPath) {
        let core = frc.object(at: indexPath)
        context.delete(core)
        saveContext()
    }

    func updateName(at indexPath: IndexPath, newName: String) {
        let core = frc.object(at: indexPath)
        core.name = newName
        saveContext()
    }

    // MARK: - Приватные утилиты
    
    private func applyFiltersAndRefetch() {
        var predicates: [NSPredicate] = []

        if let weekday = currentWeekday {
            let bit = 1 << (weekday.rawValue - 1)
            predicates.append(
                NSPredicate(format: "scheduleMask & %d != 0", bit)
            )
        }

        if let text = searchText, !text.isEmpty {
            predicates.append(
                NSPredicate(format: "name CONTAINS[cd] %@", text)
            )
        }

        if predicates.isEmpty {
            frc.fetchRequest.predicate = nil
        } else {
            frc.fetchRequest.predicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: predicates
            )
        }

        do {
            try frc.performFetch()
        } catch {
            print("FRC performFetch error:", error)
        }

        delegate?.trackerStoreDidReloadData(self)
    }

    private func getOrCreateCategory(with title: String) -> TrackerCategoryCoreData {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        return category
    }

    private func makeTracker(from core: TrackerCoreData) -> Tracker {
        let id = core.id ?? UUID()
        let name = core.name ?? "Без названия"
        let emoji = core.emoji ?? "🙂"
        let colorHex = core.colorHex ?? "#000000"
        let color = UIColor(hex: colorHex)

        let mask = core.scheduleMask
        var weekdays: [Weekday] = []

        for raw in 1...7 {
            let bit = Int16(1 << (raw - 1))
            if (mask & bit) != 0 {
                if let day = Weekday(rawValue: raw) {
                    weekdays.append(day)
                }
            }
        }

        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: weekdays
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerStore: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedSections = []
        deletedSections = []
        insertedItems = []
        deletedItems = []
        updatedItems = []
        movedItems = []

        delegate?.trackerStoreWillChangeContent(self)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidChangeContent(
            self,
            insertedSections: insertedSections,
            deletedSections: deletedSections,
            insertedItems: insertedItems,
            deletedItems: deletedItems,
            updatedItems: updatedItems,
            movedItems: movedItems
        )

        insertedSections = []
        deletedSections = []
        insertedItems = []
        deletedItems = []
        updatedItems = []
        movedItems = []
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {

        switch type {
        case .insert:
            insertedSections.insert(sectionIndex)
        case .delete:
            deletedSections.insert(sectionIndex)
        default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            if let newIndexPath { insertedItems.append(newIndexPath) }
        case .delete:
            if let indexPath { deletedItems.append(indexPath) }
        case .update:
            if let indexPath { updatedItems.append(indexPath) }
        case .move:
            if let from = indexPath, let to = newIndexPath {
                movedItems.append((from: from, to: to))
            }
        @unknown default:
            break
        }
    }
}
