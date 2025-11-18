import Foundation
import CoreData

final class TrackerRecordStore {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CRUD

    func addRecord(trackerId: UUID, date: Date) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", trackerId as CVarArg)

        guard let tracker = try context.fetch(request).first else { return }

        let entity = TrackerRecordCoreData(context: context)
        entity.date = date
        entity.tracker = tracker

        try context.save()
    }

    func deleteRecord(trackerId: UUID, date: Date) throws {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg, date as CVarArg
        )

        if let obj = try context.fetch(request).first {
            context.delete(obj)
            try context.save()
        }
    }

    func getRecords(for trackerId: UUID) throws -> [TrackerRecord] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)

        let objects = try context.fetch(request)
        return objects.map { TrackerRecord(trackerId: trackerId, date: $0.date ?? Date()) }
    }
}
