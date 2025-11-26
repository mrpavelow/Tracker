import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Data
    private let trackerRecordStore = TrackerRecordStore()
    private let trackerStore = TrackerStore()
    private var completedRecords: [TrackerRecord] = []
    
    private var currentFilter: TrackerCompletionFilter = .none
    private var filteredIndexPathsBySection: [[IndexPath]] = []
    
    private var datePicker = UIDatePicker()
    private var collectionView: UICollectionView!
    private var selectedDate = Date()
    
    // MARK: - UI
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("filters", comment: "Filters button"), for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = .ypBlue
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .addButton), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("trackers", comment: "Trackers title header")
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .done, target: self, action: #selector(hideKeyboard))
        toolbar.items = [flex, done]
        searchBar.inputAccessoryView = toolbar
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = .systemGray6
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.searchTextField.clipsToBounds = true
        searchBar.placeholder = NSLocalizedString("search", comment: "Trackers title header")
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(resource: .bgplaceholder))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("empty_label", comment: "Empty Label String")
        label.textColor = .ypBlack
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Методы для логики выполнения
    
    private func updateFilterButtonAppearance() {
        let isActive = currentFilter != .none
        filterButton.setTitleColor(isActive ? .ypRed : .white, for: .normal)
    }
    
    private func rebuildFilteredIndexPathsIfNeeded() {
        guard currentFilter != .none else {
            filteredIndexPathsBySection = []
            updateEmptyState()
            collectionView.reloadData()
            updateFilterButtonAppearance()
            return
        }
        
        var result: [[IndexPath]] = []
        let sections = trackerStore.numberOfSections()
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: selectedDate)
        
        for section in 0..<sections {
            var sectionIndexes: [IndexPath] = []
            let items = trackerStore.numberOfItems(in: section)
            
            for item in 0..<items {
                let indexPath = IndexPath(item: item, section: section)
                let tracker = trackerStore.tracker(at: indexPath)
                
                let isCompletedToday = completedRecords.contains {
                    $0.trackerId == tracker.id && calendar.isDate($0.date, inSameDayAs: day)
                }
                
                switch currentFilter {
                case .none:
                    sectionIndexes.append(indexPath)
                case .completed:
                    if isCompletedToday {
                        sectionIndexes.append(indexPath)
                    }
                case .uncompleted:
                    if !isCompletedToday {
                        sectionIndexes.append(indexPath)
                    }
                }
            }
            
            result.append(sectionIndexes)
        }
        
        filteredIndexPathsBySection = result
        updateEmptyState()
        collectionView.reloadData()
        updateFilterButtonAppearance()
    }
    
    private func loadRecords() {
        let records = trackerRecordStore.getAll()
        completedRecords = records.compactMap { coreDataRecord in
            guard let id = coreDataRecord.trackerId, let date = coreDataRecord.date else { return nil }
            return TrackerRecord(trackerId: id, date: date)
        }
    }
    
    private func toggleTrackerCompletion(for tracker: Tracker, on date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let normalizedDate = calendar.startOfDay(for: date)
        
        guard normalizedDate <= today else {
            showAlert("Нельзя отметить будущую дату")
            return
        }
        
        let record = TrackerRecord(trackerId: tracker.id, date: normalizedDate)
        
        if let index = completedRecords.firstIndex(where: { $0.trackerId == record.trackerId && $0.date == record.date }) {
            completedRecords.remove(at: index)
            trackerRecordStore.remove(record)
        } else {
            completedRecords.append(record)
            trackerRecordStore.add(record)
        }
        
        if currentFilter == .none {
            collectionView.reloadData()
            updateEmptyState()
        } else {
            rebuildFilteredIndexPathsIfNeeded()
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        searchBar.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        loadRecords()
        setupNavigationBar()
        setupCollectionView()
        updateFilterButtonAppearance()
        setupEmptyState()

        trackerStore.delegate = self

        let weekdayInt = Calendar.current.component(.weekday, from: selectedDate)
        if let weekday = Weekday(rawValue: weekdayInt) {
            trackerStore.setWeekdayFilter(weekday)
        }

        updateEmptyState()
    }
    
    // MARK: - Navigation Bar
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(addButton)
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(datePicker)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            addButton.widthAnchor.constraint(equalToConstant: 42),
            addButton.heightAnchor.constraint(equalToConstant: 42),
            
            titleLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 1),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            datePicker.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func filterTapped() {
        AnalyticsService.track(
                event: .click,
                screen: .main,
                item: .filter
            )
        let vc = FiltersViewController()
        vc.activeCompletionFilter = currentFilter
        vc.onSelect = { [weak self] option in
            guard let self else { return }

            switch option {
            case .all:
                self.currentFilter = .none
                self.rebuildFilteredIndexPathsIfNeeded()

            case .today:
                let today = Date()
                self.selectedDate = today
                self.datePicker.setDate(today, animated: true)

                let weekdayInt = Calendar.current.component(.weekday, from: today)
                if let weekday = Weekday(rawValue: weekdayInt) {
                    self.trackerStore.setWeekdayFilter(weekday)
                } else {
                    self.trackerStore.setWeekdayFilter(nil)
                }
                self.currentFilter = .none
                self.rebuildFilteredIndexPathsIfNeeded()

            case .completed:
                self.currentFilter = .completed
                self.rebuildFilteredIndexPathsIfNeeded()

            case .uncompleted:
                self.currentFilter = .uncompleted
                self.rebuildFilteredIndexPathsIfNeeded()
            }
        }

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date

        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: selectedDate)
        if let weekday = Weekday(rawValue: weekdayInt) {
            trackerStore.setWeekdayFilter(weekday)
        } else {
            trackerStore.setWeekdayFilter(nil)
        }

        rebuildFilteredIndexPathsIfNeeded()
    }
    
    @objc private func addTapped() {
        AnalyticsService.track(
                event: .click,
                screen: .main,
                item: .addTrack
            )
        let newTrackerVC = NewTrackerViewController()
        
        newTrackerVC.onCreateTracker = { _ in }
        
        let nav = UINavigationController(rootViewController: newTrackerVC)
        present(nav, animated: true)
    }

    // MARK: - CollectionView
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 16
        let interItemSpacing: CGFloat = 12
        let availableWidth = view.frame.width - (padding * 2) - interItemSpacing
        let cellWidth = availableWidth / 2
        
        layout.itemSize = CGSize(width: cellWidth, height: 148)
        
        layout.sectionInset = UIEdgeInsets(top: 16, left: padding, bottom: 24, right: padding)
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = interItemSpacing
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: 32)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(CategoryHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "CategoryHeaderView")
        
        view.addSubview(collectionView)
        view.addSubview(filterButton)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset.bottom = 16
    }
    
    // MARK: - Empty State
    
    private func setupEmptyState() {
        view.addSubview(emptyImageView)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -246),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func updateEmptyState() {
        let totalItems: Int

        if currentFilter == .none {
            var count = 0
            let sections = trackerStore.numberOfSections()
            for section in 0..<sections {
                count += trackerStore.numberOfItems(in: section)
            }
            totalItems = count
        } else {
            totalItems = filteredIndexPathsBySection.reduce(0) { $0 + $1.count }
        }

        let isEmpty = totalItems == 0
        let hasSearchText = !(searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let isFilterActive = currentFilter != .none

        if isEmpty && (hasSearchText || isFilterActive) {
            emptyLabel.text = NSLocalizedString("nothing_found", comment: "Nothing found stub")
        } else {
            emptyLabel.text = NSLocalizedString("empty_label", comment: "Empty Label String")
        }

        emptyImageView.isHidden = !isEmpty
        emptyLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension TrackersViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if currentFilter == .none {
            return trackerStore.numberOfSections()
        } else {
            return filteredIndexPathsBySection.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if currentFilter == .none {
            return trackerStore.numberOfItems(in: section)
        } else {
            return filteredIndexPathsBySection[section].count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TrackerCell",
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }

        cell.delegate = self

        let originalIndexPath: IndexPath
        if currentFilter == .none {
            originalIndexPath = indexPath
        } else {
            originalIndexPath = filteredIndexPathsBySection[indexPath.section][indexPath.item]
        }

        let tracker = trackerStore.tracker(at: originalIndexPath)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        let completedToday = completedRecords.contains {
            $0.trackerId == tracker.id && calendar.isDate($0.date, inSameDayAs: today)
        }
        let completedCount = completedRecords.filter { $0.trackerId == tracker.id }.count

        cell.configure(with: tracker,
                       completedToday: completedToday,
                       completedCount: completedCount)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "CategoryHeaderView",
                for: indexPath
              ) as? CategoryHeaderView else {
            return UICollectionReusableView()
        }
        header.titleLabel.text = trackerStore.titleForSection(indexPath.section)
        return header
    }
}

extension TrackersViewController: UICollectionViewDelegate {}

extension TrackersViewController: TrackerCellDelegate {
    func didTapPlusButton(in cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }

        let tracker = trackerStore.tracker(at: indexPath)
        toggleTrackerCompletion(for: tracker, on: selectedDate)
    }
}

extension TrackersViewController: TrackerStoreDelegate {
    func trackerStoreWillChangeContent(_ store: TrackerStore) {
        guard currentFilter == .none else { return }
    }
    
    func trackerStoreDidReloadData(_ store: TrackerStore) {
        rebuildFilteredIndexPathsIfNeeded()
    }

    func trackerStoreDidChangeContent(_ store: TrackerStore,
                                      insertedSections: IndexSet,
                                      deletedSections: IndexSet,
                                      insertedItems: [IndexPath],
                                      deletedItems: [IndexPath],
                                      updatedItems: [IndexPath],
                                      movedItems: [(from: IndexPath, to: IndexPath)]) {

        guard currentFilter == .none else {
            rebuildFilteredIndexPathsIfNeeded()
            return
        }

        collectionView.performBatchUpdates {
            if !deletedSections.isEmpty {
                collectionView.deleteSections(deletedSections)
            }
            if !insertedSections.isEmpty {
                collectionView.insertSections(insertedSections)
            }

            if !deletedItems.isEmpty {
                collectionView.deleteItems(at: deletedItems)
            }
            if !insertedItems.isEmpty {
                collectionView.insertItems(at: insertedItems)
            }
            if !updatedItems.isEmpty {
                collectionView.reloadItems(at: updatedItems)
            }
            for move in movedItems {
                collectionView.moveItem(at: move.from, to: move.to)
            }
        } completion: { _ in
            self.updateEmptyState()
        }
    }
}

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        trackerStore.setSearchText(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
