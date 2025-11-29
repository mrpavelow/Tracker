import UIKit

final class FiltersViewController: UIViewController {

    enum Option: Int, CaseIterable {
        case all
        case today
        case completed
        case uncompleted

        var title: String {
            switch self {
            case .all:
                return NSLocalizedString("filters_all", comment: "All trackers")
            case .today:
                return NSLocalizedString("filters_today", comment: "Trackers for today")
            case .completed:
                return NSLocalizedString("filters_completed", comment: "Completed")
            case .uncompleted:
                return NSLocalizedString("filters_uncompleted", comment: "Uncompleted")
            }
        }
    }

    var activeCompletionFilter: TrackerCompletionFilter = .none
    var onSelect: ((Option) -> Void)?

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("filters", comment: "Filters screen header")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .systemBackground
        table.layer.masksToBounds = true
        return table
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FilterCell.self, forCellReuseIdentifier: FilterCell.reuseID)
    }

    // MARK: - Helpers

    private func isOptionActive(_ option: Option) -> Bool {
        switch option {
        case .completed:
            return activeCompletionFilter == .completed
        case .uncompleted:
            return activeCompletionFilter == .uncompleted
        case .all, .today:
            return false
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension FiltersViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                       heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 75
        }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Option.allCases.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FilterCell.reuseID,
            for: indexPath
        ) as? FilterCell,
              let option = Option(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        cell.configure(title: option.title, isSelected: isOptionActive(option))
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = Option(rawValue: indexPath.row) else { return }

        onSelect?(option)
        dismiss(animated: true)
    }
}

// MARK: - Custom Cell

private final class FilterCell: UITableViewCell {

    static let reuseID = "FilterCell"

    private let titleLabel = UILabel()
    private let checkmarkView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func setup() {
        selectionStyle = .none
        contentView.backgroundColor = UIColor(resource: .ypBackground)

        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.image = UIImage(systemName: "checkmark")
        checkmarkView.tintColor = .ypBlue
        checkmarkView.isHidden = true

        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 16),
            checkmarkView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        checkmarkView.isHidden = !isSelected
    }
}
