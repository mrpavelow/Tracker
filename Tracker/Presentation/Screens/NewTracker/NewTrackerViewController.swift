import UIKit

final class NewTrackerViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("warning_label", comment: "Character limit label")
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("new_habit", comment: "Trackers title header")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.layer.masksToBounds = true
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var newTrackerTextField: UITextField = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .done, target: self, action: #selector(hideKeyboard))
        toolbar.items = [flex, done]
        let textField = UITextField()
        textField.inputAccessoryView = toolbar
        textField.clearButtonMode = .whileEditing
        textField.placeholder = NSLocalizedString("type_tracker_name", comment: "Trackers title header")
        textField.backgroundColor = UIColor(resource: .ypBackground)
        textField.layer.cornerRadius = 16
        textField.layer.masksToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("category", comment: "Category selector"), for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let scheduleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("schedule", comment: "Schedule selector"), for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("cancel_create_button", comment: "Cancel button"), for: .normal)
        button.setTitleColor(.ypRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.backgroundColor = .ypWhite
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("create_button", comment: "Create button"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.layer.cornerRadius = 16
        button.backgroundColor = .ypGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("emoji_chooser_header", comment: "Emoji chooser header")
        label.font = .boldSystemFont(ofSize: 19)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("color_chooser_header", comment: "Color chooser header")
        label.font = .boldSystemFont(ofSize: 19)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emojiCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 52, height: 52)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 24, left: 18, bottom: 0, right: 18)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.heightAnchor.constraint(equalToConstant: 204).isActive = true
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        return cv
    }()
    
    private lazy var colorCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 52, height: 52)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 24, left: 18, bottom: 0, right: 18)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.heightAnchor.constraint(equalToConstant: 204).isActive = true
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        return cv
    }()
    
    
    // MARK: - Data
    
    var onCreateTracker: ((Tracker) -> Void)?
    
    private let trackerStore = TrackerStore()
    
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private var tableTopConstraint: NSLayoutConstraint!
    private var selectedCategory: String?
    private var selectedDays: [String] = []
    
    private let dayKeys = [
        "monday", "tuesday", "wednesday",
        "thursday", "friday", "saturday", "sunday"
    ]
    
    private let dayShortByKey: [String: String] = [
        "monday": NSLocalizedString("monday_short", comment: ""),
        "tuesday": NSLocalizedString("tuesday_short", comment: ""),
        "wednesday": NSLocalizedString("wednesday_short", comment: ""),
        "thursday": NSLocalizedString("thursday_short", comment: ""),
        "friday": NSLocalizedString("friday_short", comment: ""),
        "saturday": NSLocalizedString("saturday_short", comment: ""),
        "sunday": NSLocalizedString("sunday_short", comment: "")
    ]
    
    private let emojiArray: [String] = [
        "🙂","😻","🌺","🐶","❤️","😱",
        "😇","😡","🥶","🤔","🙌","🍔",
        "🥦","🏓","🥇","🎸","🏝","😪"
    ]
    
    private let colorArray: [UIColor] = [
        .colorSelection1, .colorSelection2, .colorSelection3,
        .colorSelection4, .colorSelection5, .colorSelection6,
        .colorSelection7, .colorSelection8, .colorSelection9,
        .colorSelection10, .colorSelection11, .colorSelection12,
        .colorSelection13, .colorSelection14, .colorSelection15,
        .colorSelection16, .colorSelection17, .colorSelection18
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(newTrackerTextField)
        contentView.addSubview(warningLabel)
        contentView.addSubview(tableView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCollection)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorCollection)
        
        setupTable()
        setupLayout()
        setupMenus()
        newTrackerTextField.delegate = self
        updateCreateButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Database Layer
    
    func saveTrackerToDatabase() {
        
        guard
            let name = newTrackerTextField.text, !name.isEmpty,
            let emoji = selectedEmoji,
            let color = selectedColor,
            !selectedDays.isEmpty,
            let categoryTitle = selectedCategory
        else {
            return
        }
        
        _ = dayKeys.map { NSLocalizedString($0, comment: "") }
                
        let scheduleInts: [Int] = selectedDays.compactMap {
            switch $0 {
            case "monday":    return 2
            case "tuesday":   return 3
            case "wednesday": return 4
            case "thursday":  return 5
            case "friday":    return 6
            case "saturday":  return 7
            case "sunday":    return 1
            default:          return nil
            }
        }
        
        trackerStore.addTracker(
            name: name,
            emoji: emoji,
            colorHex: color.toHex(),
            categoryTitle: categoryTitle,
            schedule: scheduleInts
        )
        
        dismiss(animated: true)
    }
    
    private func updateCreateButtonState() {
        let hasName      = !(newTrackerTextField.text?.isEmpty ?? true)
        let hasDays      = !selectedDays.isEmpty
        let hasCategory  = (selectedCategory != nil)
        
        let enabled = hasName && hasDays && hasCategory
        createButton.isEnabled = enabled
        
        UIView.animate(withDuration: 0.2) {
            self.createButton.backgroundColor = enabled ? .ypBlack : .ypGray
        }
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        
        let buttonsStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        buttonsStack.distribution = .fillEqually
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStack)
        
        tableTopConstraint = tableView.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            newTrackerTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            newTrackerTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            newTrackerTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            newTrackerTextField.heightAnchor.constraint(equalToConstant: 75),
            
            warningLabel.topAnchor.constraint(equalTo: newTrackerTextField.bottomAnchor, constant: 8),
            warningLabel.centerXAnchor.constraint(equalTo: newTrackerTextField.centerXAnchor),
            
            tableTopConstraint,
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 150),
            
            emojiLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 32),
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            emojiCollection.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor),
            emojiCollection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            colorLabel.topAnchor.constraint(equalTo: emojiCollection.bottomAnchor, constant: 16),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            colorCollection.topAnchor.constraint(equalTo: colorLabel.bottomAnchor),
            colorCollection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorCollection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorCollection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
            
            cancelButton.widthAnchor.constraint(equalToConstant: 160),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            createButton.widthAnchor.constraint(equalToConstant: 160),
            createButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }
    
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "catCell")
    }
    
    private func setupMenus() {
        scheduleButton.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)
        categoryButton.addTarget(self, action: #selector(categoryTapped), for: .touchUpInside)
        
    }
    
    // MARK: - Actions
    
    @objc private func categoryTapped() {
        let viewModel = CategoryListViewModel(
            selectedCategoryTitle: selectedCategory
        )
        let vc = CategoryListViewController(viewModel: viewModel)
        
        vc.onCategorySelected = { [weak self] category in
            guard let self else { return }
            
            self.selectedCategory = category.title
            self.updateCreateButtonState()
            
            guard !category.title.isEmpty else {
                self.categoryButton.setTitle(NSLocalizedString("category", comment: "Categroy button"), for: .normal)
                self.categoryButton.setAttributedTitle(nil, for: .normal)
                return
            }
            
            let titleFont = UIFont.systemFont(ofSize: 17, weight: .regular)
            let categoryFont = UIFont.systemFont(ofSize: 17, weight: .regular)
            
            let titleColor = UIColor.label
            let categoryColor = UIColor.ypGray
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 2
            paragraph.alignment = .left
            
            let result = NSMutableAttributedString(
                string: NSLocalizedString("category_next", comment: ""),
                attributes: [
                    .font: titleFont,
                    .foregroundColor: titleColor,
                    .paragraphStyle: paragraph
                ]
            )
            
            let value = NSAttributedString(
                string: category.title,
                attributes: [
                    .font: categoryFont,
                    .foregroundColor: categoryColor,
                    .paragraphStyle: paragraph
                ]
            )
            result.append(value)
            
            self.categoryButton.setAttributedTitle(result, for: .normal)
            self.categoryButton.titleLabel?.numberOfLines = 0
        }
        
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func scheduleTapped() {
        let vc = ScheduleSelectorViewController(
            days: dayKeys,
            selected: selectedDays
        )
        
        vc.onSelectionChanged = { [weak self] newSelected in
            guard let self else { return }
            
            self.selectedDays = newSelected
            self.updateCreateButtonState()
            
            let dayShortByKey: [String: String] = [
                "monday": NSLocalizedString("monday_short", comment: ""),
                "tuesday": NSLocalizedString("tuesday_short", comment: ""),
                "wednesday": NSLocalizedString("wednesday_short", comment: ""),
                "thursday": NSLocalizedString("thursday_short", comment: ""),
                "friday": NSLocalizedString("friday_short", comment: ""),
                "saturday": NSLocalizedString("saturday_short", comment: ""),
                "sunday": NSLocalizedString("sunday_short", comment: ""),
            ]
            
            let short = selectedDays.compactMap { dayShortByKey[$0] }
            let formatted = short.joined(separator: ", ")
            
            if formatted.isEmpty {
                self.scheduleButton.setAttributedTitle(nil, for: .normal)
                self.scheduleButton.setTitle(NSLocalizedString("schedule", comment: "Schedule button"), for: .normal)
                return
            }
            
            let titleFont = UIFont.systemFont(ofSize: 17, weight: .regular)
            let daysFont  = UIFont.systemFont(ofSize: 17, weight: .regular)
            
            let titleColor = UIColor.label
            let daysColor  = UIColor.ypGray
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 2
            paragraph.alignment = .left
            
            let result = NSMutableAttributedString(
                string: NSLocalizedString("schedule_next", comment: ""),
                attributes: [
                    .font: titleFont,
                    .foregroundColor: titleColor,
                    .paragraphStyle: paragraph
                ]
            )
            
            let daysPart = NSAttributedString(
                string: formatted,
                attributes: [
                    .font: daysFont,
                    .foregroundColor: daysColor,
                    .paragraphStyle: paragraph
                ]
            )
            
            result.append(daysPart)
            
            self.scheduleButton.setAttributedTitle(result, for: .normal)
            self.scheduleButton.titleLabel?.numberOfLines = 0
        }
        
        present(vc, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createTapped() {
        guard
            let name = newTrackerTextField.text, !name.isEmpty,
            let emoji = selectedEmoji,
            let color = selectedColor,
            !selectedDays.isEmpty,
            let categoryTitle = selectedCategory
        else {
            return
        }
        
        _ = dayKeys.map { NSLocalizedString($0, comment: "") }
                
        let scheduleInts: [Int] = selectedDays.compactMap {
            switch $0 {
            case "monday":    return 2
            case "tuesday":   return 3
            case "wednesday": return 4
            case "thursday":  return 5
            case "friday":    return 6
            case "saturday":  return 7
            case "sunday":    return 1
            default:          return nil
            }
        }
        
        trackerStore.addTracker(
            name: name,
            emoji: emoji,
            colorHex: color.toHex(),
            categoryTitle: categoryTitle,
            schedule: scheduleInts
        )
        
        let tracker = Tracker(
            id: UUID(),
            name: name,
            color: color,
            emoji: emoji,
            schedule: scheduleInts.compactMap { Weekday(rawValue: $0) }
        )
        onCreateTracker?(tracker)
        
        dismiss(animated: true)
    }
}

// MARK: - Cell Classes

final class EmojiCell: UICollectionViewCell {
    
    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 32)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    func configure(_ emoji: String, selected: Bool) {
        label.text = emoji
        contentView.backgroundColor = selected ? UIColor.systemGray5 : .clear
    }
}

final class ColorCell: UICollectionViewCell {
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
        
        NSLayoutConstraint.activate([
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40),
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    func configure(_ color: UIColor, selected: Bool) {
        colorView.backgroundColor = color
        
        if selected {
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        } else {
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = nil
        }
    }
}

// MARK: - TableView Delegate & DataSource

extension NewTrackerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "catCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = UIColor.ypBackground
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let chevronView = UIImageView(image: UIImage(resource: .chevron))
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        
        if indexPath.section == 0 {
            cell.contentView.addSubview(chevronView)
            cell.contentView.addSubview(categoryButton)
            categoryButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chevronView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                chevronView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                chevronView.widthAnchor.constraint(equalToConstant: 7),
                chevronView.heightAnchor.constraint(equalToConstant: 12),
                categoryButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                categoryButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                categoryButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                categoryButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
        } else {
            cell.contentView.addSubview(chevronView)
            cell.contentView.addSubview(scheduleButton)
            scheduleButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chevronView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                chevronView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                chevronView.widthAnchor.constraint(equalToConstant: 7),
                chevronView.heightAnchor.constraint(equalToConstant: 12),
                scheduleButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                scheduleButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                scheduleButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                scheduleButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
        }
        let cornerRadius: CGFloat = 16
        let maskPath: UIBezierPath
        if indexPath.section == 0 {
            maskPath = UIBezierPath(roundedRect: cell.bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        } else if indexPath.section == tableView.numberOfSections - 1 {
            maskPath = UIBezierPath(roundedRect: cell.bounds,
                                    byRoundingCorners: [.bottomLeft, .bottomRight],
                                    cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        } else {
            maskPath = UIBezierPath(rect: cell.bounds)
        }
        let maskLayer = CAShapeLayer()
        maskLayer.frame = cell.bounds
        maskLayer.path = maskPath.cgPath
        cell.contentView.layer.mask = maskLayer
        
        if indexPath.section == 0 {
            let separator = UIView()
            separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            separator.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 1),
                separator.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                separator.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
            ])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layoutIfNeeded()
    }
}

extension NewTrackerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollection { return emojiArray.count }
        return colorArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == emojiCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
            let emoji = emojiArray[indexPath.item]
            cell.configure(emoji, selected: emoji == selectedEmoji)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
        let color = colorArray[indexPath.item]
        cell.configure(color, selected: color == selectedColor)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == emojiCollection {
            selectedEmoji = emojiArray[indexPath.item]
            emojiCollection.reloadData()
        } else {
            selectedColor = colorArray[indexPath.item]
            colorCollection.reloadData()
        }
        
        updateCreateButtonState()
    }
}

// MARK: - Textfield Characters Warning

extension NewTrackerViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        let showWarning = updatedText.count > 38
        
        UIView.animate(withDuration: 0.25) {
            self.warningLabel.isHidden = !showWarning
            self.tableTopConstraint.constant = showWarning ? 24 : 0
            self.view.layoutIfNeeded()
        }
        DispatchQueue.main.async { self.updateCreateButtonState() }
        return updatedText.count <= 38
    }
}
