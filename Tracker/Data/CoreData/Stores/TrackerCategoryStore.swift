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

extension TrackerCategoryStore {

    func renameCategory(oldTitle: String, newTitle: String) {
        guard let category = fetchCategory(withTitle: oldTitle) else { return }
        category.title = newTitle
        saveContext()
    }

    func deleteCategory(withTitle title: String) {
        guard let category = fetchCategory(withTitle: title) else { return }
        context.delete(category)
        saveContext()
    }

    private func fetchCategory(withTitle title: String) -> TrackerCategoryCoreData? {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
