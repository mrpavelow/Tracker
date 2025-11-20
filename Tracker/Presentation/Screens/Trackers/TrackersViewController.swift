import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Data
    private let trackerRecordStore = TrackerRecordStore()
    private let trackerStore = TrackerStore()
    private let trackerConverter = TrackerConverter()
    
    private var categories: [TrackerCategory] = []
    private var completedRecords: [TrackerRecord] = []
    
    private var trackers: [Tracker] = []
    
    private var datePicker = UIDatePicker()
    private var collectionView: UICollectionView!
    private var selectedDate = Date()
    
    private var trackersForSelectedDate: [Tracker] {
        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: selectedDate)
        
        guard let weekday = Weekday(rawValue: weekdayInt) else { return [] }
        
        return trackers.filter { tracker in
            tracker.schedule.contains(weekday)
        }
    }
    
    // MARK: - UI
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
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(hideKeyboard))
        toolbar.items = [flex, done]
        searchBar.inputAccessoryView = toolbar
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = .systemGray6
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.searchTextField.clipsToBounds = true
        searchBar.placeholder = "Поиск"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "bgplaceholder"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textColor = .black
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Методы для логики выполнения
    
    private func loadTrackersFromStore() {
        let coreTrackers = trackerStore.getAll()
        print(">>> loadTrackersFromStore, count =", coreTrackers.count)
        
        let mappedTrackers: [Tracker] = coreTrackers.compactMap {
            trackerConverter.makeTracker(from: $0)
        }
        self.trackers = mappedTrackers
        
        var grouped: [String: [Tracker]] = [:]
        
        for (index, core) in coreTrackers.enumerated() {
            guard index < mappedTrackers.count else { continue }
            let tracker = mappedTrackers[index]
            
            let categoryTitle = core.category?.title ?? "Без категории"
            grouped[categoryTitle, default: []].append(tracker)
        }
        
        self.categories = grouped
            .map { TrackerCategory(title: $0.key, trackers: $0.value) }
            .sorted { $0.title < $1.title }
        
        collectionView.reloadData()
        updateEmptyState()
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
        
        collectionView.reloadData()
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        categories = [
            TrackerCategory(title: "Здоровье", trackers: trackers)
        ]
        loadRecords()
        setupNavigationBar()
        setupCollectionView()
        setupEmptyState()
        updateEmptyState()
        loadTrackersFromStore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrackersFromStore()
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
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        collectionView.reloadData()
        updateEmptyState()
    }
    
    @objc private func addTapped() {
        let newTrackerVC = NewTrackerViewController()
        
        newTrackerVC.onCreateTracker = { [weak self] _ in
            self?.loadTrackersFromStore()
        }
        
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
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
        let isEmpty = trackersForSelectedDate.isEmpty
        emptyImageView.isHidden = !isEmpty
        emptyLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let category = categories[section]
        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: selectedDate)
        
        guard let weekday = Weekday(rawValue: weekdayInt) else { return 0 }
        
        let filtered = category.trackers.filter { tracker in
            tracker.schedule.contains(weekday)
        }
        
        return filtered.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCell", for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        cell.delegate = self
        
        let category = categories[indexPath.section]
        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: selectedDate)
        
        guard let weekday = Weekday(rawValue: weekdayInt) else { return cell }
        let filteredTrackers = category.trackers.filter { $0.schedule.contains(weekday) }
        let tracker = filteredTrackers[indexPath.item]
        let today = calendar.startOfDay(for: selectedDate)
        let completedToday = completedRecords.contains {
            $0.trackerId == tracker.id && calendar.isDate($0.date, inSameDayAs: today)
        }
        let completedCount = completedRecords.filter { $0.trackerId == tracker.id }.count
        cell.configure(with: tracker, completedToday: completedToday, completedCount: completedCount)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                           withReuseIdentifier: "CategoryHeaderView",
                                                                           for: indexPath) as? CategoryHeaderView else {
            return UICollectionReusableView()
        }
        
        header.titleLabel.text = categories[indexPath.section].title
        return header
    }
}

extension TrackersViewController: UICollectionViewDelegate {}

extension TrackersViewController: TrackerCellDelegate {
    func didTapPlusButton(in cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let category = categories[indexPath.section]
        
        let calendar = Calendar.current
        let weekdayInt = calendar.component(.weekday, from: selectedDate)
        guard let weekday = Weekday(rawValue: weekdayInt) else { return }
        
        let filteredTrackers = category.trackers.filter { $0.schedule.contains(weekday) }
        guard indexPath.item < filteredTrackers.count else { return }
        
        let tracker = filteredTrackers[indexPath.item]
        toggleTrackerCompletion(for: tracker, on: selectedDate)
    }
}


