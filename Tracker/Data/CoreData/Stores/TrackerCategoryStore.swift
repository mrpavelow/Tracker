import CoreData
import UIKit

final class TrackerCategoryStore {
    
    private let context: NSManagedObjectContext
    private let saveContext: () -> Void
    
    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.context
        self.saveContext = appDelegate.saveContext
    }
    
    func addCategory(title: String) -> TrackerCategoryCoreData {
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        saveContext()
        return category
    }
    
    func getAll() -> [TrackerCategoryCoreData] {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    func delete(_ category: TrackerCategoryCoreData) {
        context.delete(category)
        saveContext()
    }
}
