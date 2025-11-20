import CoreData
import UIKit

final class TrackerRecordStore {
    private let context: NSManagedObjectContext
    private let saveContext: () -> Void
    
    init(context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).context,
         saveContext: @escaping () -> Void = (UIApplication.shared.delegate as! AppDelegate).saveContext) {
        self.context = context
        self.saveContext = saveContext
    }
    
    func getAll() -> [TrackerRecordCoreData] {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch records:", error)
            return []
        }
    }
    
    func add(_ record: TrackerRecord) {
        let entity = TrackerRecordCoreData(context: context)
        entity.trackerId = record.trackerId
        entity.date = record.date
        saveContext()
    }
    
    func remove(_ record: TrackerRecord) {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", record.trackerId as CVarArg, record.date as CVarArg)
        if let objects = try? context.fetch(request) {
            for obj in objects {
                context.delete(obj)
            }
            saveContext()
        }
    }
}
