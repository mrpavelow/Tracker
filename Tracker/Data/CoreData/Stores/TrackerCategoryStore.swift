import UIKit
import CoreData

final class TrackerCategoryStore {
    
    private let context: NSManagedObjectContext
    private let saveContext: () -> Void
    
    init(
        context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).context,
        saveContext: @escaping () -> Void = (UIApplication.shared.delegate as! AppDelegate).saveContext
    ) {
        self.context = context
        self.saveContext = saveContext
    }
    
    func getAll() -> [TrackerCategoryCoreData] {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            let result = try context.fetch(request)
            print(">>> CategoryStore.getAll count =", result.count)
            return result
        } catch {
            print("Failed to fetch categories:", error)
            return []
        }
    }
    
    @discardableResult
    func addCategory(title: String) -> TrackerCategoryCoreData {
        let entity = TrackerCategoryCoreData(context: context)
        entity.title = title
        saveContext()
        print(">>> CategoryStore.addCategory =", title)
        return entity
    }
}
