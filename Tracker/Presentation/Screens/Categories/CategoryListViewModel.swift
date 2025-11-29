import Foundation

final class CategoryListViewModel {
    
    // MARK: - Dependencies
    private let store = TrackerCategoryStore()
    
    // MARK: - State
    
    private(set) var categories: [TrackerCategory] = [] {
        didSet {
            onCategoriesChanged?(categories)
        }
    }
    
    private(set) var selectedCategoryTitle: String?
    
    // MARK: - Bindings
    
    var onCategoriesChanged: (([TrackerCategory]) -> Void)?
    
    var onCategorySelected: ((TrackerCategory) -> Void)?
    
    // MARK: - Init
    
    init(selectedCategoryTitle: String? = nil) {
        self.selectedCategoryTitle = selectedCategoryTitle
    }
    
    // MARK: - API для контроллера
    
    func reload() {
        let coreCategories = store.getAll()
        categories = coreCategories.map {
            TrackerCategory(title: $0.title ?? "", trackers: [])
        }
    }
    
    func addCategory(title: String) {
        store.addCategory(title: title)
        reload()
    }
    
    func numberOfRows() -> Int {
        categories.count
    }
    
    func category(at indexPath: IndexPath) -> TrackerCategory {
        categories[indexPath.row]
    }
    
    // MARK: - Selection

    func renameCategory(at index: Int, to newTitle: String) {
        guard index >= 0 && index < categories.count else { return }
        let category = categories[index]

        store.renameCategory(oldTitle: category.title, newTitle: newTitle)
        reload()
    }

    func deleteCategory(at index: Int) {
        guard index >= 0 && index < categories.count else { return }
        let category = categories[index]

        store.deleteCategory(withTitle: category.title)
        reload()
    }
    
    func isSelected(at indexPath: IndexPath) -> Bool {
        categories[indexPath.row].title == selectedCategoryTitle
    }
    
    @discardableResult
    func selectCategory(at indexPath: IndexPath) -> TrackerCategory {
        let category = categories[indexPath.row]
        selectedCategoryTitle = category.title
        onCategorySelected?(category)
        return category
    }
}
