import UIKit

final class EditTrackerViewController: UIViewController {

    // MARK: - Public

    var onSave: (
        _ name: String,
        _ emoji: String,
        _ color: UIColor,
        _ dayKeys: [String],
        _ categoryTitle: String
    ) -> Void = { _,_,_,_,_ in }

    private let tracker: Tracker
    private let trackerStore: TrackerStore
    private let initialCategoryTitle: String
    private let completedDaysCount: Int

    // MARK: - UI

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
        label.text = NSLocalizedString("warning_label", comment: "")
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("edit_habit", comment: "Edit habit screen title")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let daysLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .ypBlack
        label.textAlignment = .center
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

    private lazy var nameTextField: UITextField = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(
            title: NSLocalizedString("done", comment: ""),
            style: .done,
            target: self,
            action: #selector(hideKeyboard)
        )
        toolbar.items = [flex, done]

        let textField = UITextField()
        textField.inputAccessoryView = toolbar
        textField.clearButtonMode = .whileEditing
        textField.placeholder = NSLocalizedString("type_tracker_name", comment: "")
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
        button.setTitle(NSLocalizedString("category", comment: ""), for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()

    private let scheduleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("schedule", comment: ""), for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("cancel_create_button", comment: ""), for: .normal)
        button.setTitleColor(.ypRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.backgroundColor = .ypWhite
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("save_button", comment: "Save button"), for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.layer.cornerRadius = 16
        button.backgroundColor = .ypGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("emoji_chooser_header", comment: "")
        label.font = .boldSystemFont(ofSize: 19)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("color_chooser_header", comment: "")
        label.font = .boldSystemFont(ofSize: 19)
        label.textColor = .ypBlack
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

    private var tableTopConstraint: NSLayoutConstraint!

    private var selectedEmoji: String?
    private var selectedColor: UIColor?
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

    // MARK: - Init

    init(tracker: Tracker,
         categoryTitle: String,
         completedDays: Int,
         trackerStore: TrackerStore) {
        self.tracker = tracker
        self.initialCategoryTitle = categoryTitle
        self.completedDaysCount = completedDays
        self.trackerStore = trackerStore

        self.selectedEmoji = tracker.emoji
        self.selectedCategory = categoryTitle
        let trackerColor = tracker.color
        self.selectedColor = trackerColor

        super.init(nibName: nil, bundle: nil)

        let targetHex = trackerColor.toHex()
        if let index = colorArray.firstIndex(where: { $0.toHex() == targetHex }) {
            self.selectedColor = colorArray[index]
        }
        self.selectedDays = tracker.schedule.map { dayKey(for: $0) }
        modalPresentationStyle = .formSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

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
        contentView.addSubview(daysLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(warningLabel)
        contentView.addSubview(tableView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCollection)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorCollection)

        setupTable()
        setupLayout()
        setupMenus()

        nameTextField.delegate = self

        nameTextField.text = tracker.name
        daysLabel.text = String(
            format: NSLocalizedString("days_completed", comment: ""),
            completedDaysCount
        )
        updateCategoryButtonTitle()
        updateScheduleButtonTitle()
        updateSaveButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Layout / Setup

    private func setupLayout() {
        let buttonsStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
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

            daysLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            daysLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            nameTextField.topAnchor.constraint(equalTo: daysLabel.bottomAnchor, constant: 40),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),

            warningLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            warningLabel.centerXAnchor.constraint(equalTo: nameTextField.centerXAnchor),

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

            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            saveButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
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

    // MARK: - Helpers

    private func dayKey(for weekday: Weekday) -> String {
        switch weekday {
        case .monday:    return "monday"
        case .tuesday:   return "tuesday"
        case .wednesday: return "wednesday"
        case .thursday:  return "thursday"
        case .friday:    return "friday"
        case .saturday:  return "saturday"
        case .sunday:    return "sunday"
        }
    }

    private func updateSaveButtonState() {
        let hasName      = !(nameTextField.text?.isEmpty ?? true)
        let hasDays      = !selectedDays.isEmpty
        let hasCategory  = (selectedCategory != nil)
        let enabled = hasName && hasDays && hasCategory

        saveButton.isEnabled = enabled
        UIView.animate(withDuration: 0.2) {
            self.saveButton.backgroundColor = enabled ? .ypBlack : .ypGray
        }
    }

    private func updateCategoryButtonTitle() {
        guard let title = selectedCategory, !title.isEmpty else {
            categoryButton.setAttributedTitle(nil, for: .normal)
            categoryButton.setTitle(NSLocalizedString("category", comment: ""), for: .normal)
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
            string: title,
            attributes: [
                .font: categoryFont,
                .foregroundColor: categoryColor,
                .paragraphStyle: paragraph
            ]
        )
        result.append(value)

        categoryButton.setAttributedTitle(result, for: .normal)
        categoryButton.titleLabel?.numberOfLines = 0
    }

    private func updateScheduleButtonTitle() {
        let short = selectedDays.compactMap { dayShortByKey[$0] }
        let formatted = short.joined(separator: ", ")

        if formatted.isEmpty {
            scheduleButton.setAttributedTitle(nil, for: .normal)
            scheduleButton.setTitle(NSLocalizedString("schedule", comment: ""), for: .normal)
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

        scheduleButton.setAttributedTitle(result, for: .normal)
        scheduleButton.titleLabel?.numberOfLines = 0
    }

    // MARK: - Actions

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard
            let name = nameTextField.text, !name.isEmpty,
            let emoji = selectedEmoji,
            let color = selectedColor,
            !selectedDays.isEmpty,
            let categoryTitle = selectedCategory
        else {
            return
        }

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

        trackerStore.updateTracker(
            id: tracker.id,
            name: name,
            emoji: emoji,
            colorHex: color.toHex(),
            categoryTitle: categoryTitle,
            schedule: scheduleInts
        )

        onSave(name, emoji, color, selectedDays, categoryTitle)
        dismiss(animated: true)
    }

    @objc private func categoryTapped() {
        let viewModel = CategoryListViewModel(
            selectedCategoryTitle: selectedCategory
        )
        let vc = CategoryListViewController(viewModel: viewModel)

        vc.onCategorySelected = { [weak self] category in
            guard let self else { return }

            self.selectedCategory = category.title
            self.updateSaveButtonState()
            self.updateCategoryButtonTitle()
        }

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    @objc private func scheduleTapped() {
        let vc = ScheduleSelectorViewController(
            days: dayKeys,
            selected: selectedDays
        )

        vc.onSelectionChanged = { [weak self] newSelected in
            guard let self else { return }
            self.selectedDays = newSelected
            self.updateSaveButtonState()
            self.updateScheduleButtonTitle()
        }

        present(vc, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension EditTrackerViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "catCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = UIColor(resource: .ypBackground)
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
            maskPath = UIBezierPath(
                roundedRect: cell.bounds,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
        } else {
            maskPath = UIBezierPath(
                roundedRect: cell.bounds,
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
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

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        cell.contentView.layoutIfNeeded()
    }
}

// MARK: - UICollectionView

extension EditTrackerViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        collectionView == emojiCollection ? emojiArray.count : colorArray.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == emojiCollection {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "EmojiCell",
                for: indexPath
            ) as! EmojiCell
            let emoji = emojiArray[indexPath.item]
            cell.configure(emoji, selected: emoji == selectedEmoji)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ColorCell",
            for: indexPath
        ) as! ColorCell
        let color = colorArray[indexPath.item]
        cell.configure(color, selected: color == selectedColor)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollection {
            selectedEmoji = emojiArray[indexPath.item]
            emojiCollection.reloadData()
        } else {
            selectedColor = colorArray[indexPath.item]
            colorCollection.reloadData()
        }
        updateSaveButtonState()
    }
}

// MARK: - TextField limit

extension EditTrackerViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        let showWarning = updatedText.count > 38

        UIView.animate(withDuration: 0.25) {
            self.warningLabel.isHidden = !showWarning
            self.tableTopConstraint.constant = showWarning ? 24 : 0
            self.view.layoutIfNeeded()
        }

        DispatchQueue.main.async { self.updateSaveButtonState() }
        return updatedText.count <= 38
    }
}
