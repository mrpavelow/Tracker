import UIKit

final class NewTrackerViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
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
    
    private let nameTextField: UITextField = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(hideKeyboard))
        toolbar.items = [flex, done]
        let textField = UITextField()
        textField.inputAccessoryView = toolbar
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Введите название трекера"
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
        button.setTitle("Категория", for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let scheduleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Расписание", for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.ypRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ypRed.cgColor
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.layer.cornerRadius = 16
        button.backgroundColor = .ypGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Data
    
    var onCreateTracker: ((Tracker) -> Void)?
    
    private var tableTopConstraint: NSLayoutConstraint!
    private var selectedCategory: String?
    private var selectedDays: [String] = []
    private let allCategories = ["Здоровье", "Учёба", "Работа", "Отдых"]
    private let allDays = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    private let dayShort: [String: String] = [
        "Понедельник": "Пн",
        "Вторник": "Вт",
        "Среда": "Ср",
        "Четверг": "Чт",
        "Пятница": "Пт",
        "Суббота": "Сб",
        "Воскресенье": "Вс"
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(titleLabel)
        view.addSubview(nameTextField)
        view.addSubview(warningLabel)
        view.addSubview(tableView)
        setupTable()
        setupLayout()
        setupMenus()
        nameTextField.delegate = self
        updateCreateButtonState()
    }
    
    // MARK: - Layout
    
    private func updateCreateButtonState() {
        let hasName = !(nameTextField.text?.isEmpty ?? true)
        let hasDays = !selectedDays.isEmpty
        let enabled = hasName && hasDays
        createButton.isEnabled = enabled

        UIView.animate(withDuration: 0.2) {
            self.createButton.backgroundColor = enabled ? .ypBlack : .ypGray
        }
    }
    
    private func setupLayout() {
        let buttonsStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        buttonsStack.distribution = .fillEqually
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStack)
        tableTopConstraint = tableView.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34),
            
            cancelButton.widthAnchor.constraint(equalToConstant: 160),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            createButton.widthAnchor.constraint(equalToConstant: 160),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            warningLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            warningLabel.centerXAnchor.constraint(equalTo: nameTextField.centerXAnchor),
            
            tableTopConstraint,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 200)
        ])
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }
    
    // MARK: - Table setup
    
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "catCell")
    }
    
    // MARK: - Setup Menus
    
    private func setupMenus() {
        scheduleButton.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func scheduleTapped() {
        let vc = ScheduleSelectorViewController(days: allDays, selected: selectedDays)
        
        vc.onSelectionChanged = { [weak self] newSelected in
            guard let self else { return }
            
            self.selectedDays = newSelected
            self.updateCreateButtonState()
            
            let dayShort: [String: String] = [
                "Понедельник": "Пн",
                "Вторник": "Вт",
                "Среда": "Ср",
                "Четверг": "Чт",
                "Пятница": "Пт",
                "Суббота": "Сб",
                "Воскресенье": "Вс"
            ]
            
            let short = newSelected.compactMap { dayShort[$0] }
            let formatted = short.joined(separator: ", ")
            
            if formatted.isEmpty {
                self.scheduleButton.setAttributedTitle(nil, for: .normal)
                self.scheduleButton.setTitle("Расписание", for: .normal)
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
                string: "Расписание:\n",
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
        guard let name = nameTextField.text, !name.isEmpty else { return }

        let weekdays: [Weekday] = selectedDays.compactMap { dayName in
            switch dayName {
            case "Понедельник": return .monday
            case "Вторник": return .tuesday
            case "Среда": return .wednesday
            case "Четверг": return .thursday
            case "Пятница": return .friday
            case "Суббота": return .saturday
            case "Воскресенье": return .sunday
            default: return nil
            }
        }

        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: .ypRed,
            emoji: "⭐️",
            schedule: weekdays
        )

        onCreateTracker?(newTracker)

        dismiss(animated: true)
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
        let chevronView = UIImageView(image: UIImage(named: "chevron"))
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
