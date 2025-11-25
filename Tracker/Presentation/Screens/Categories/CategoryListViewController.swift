import UIKit

final class CategoryListViewController: UIViewController {
    
    // MARK: - Public

    var onCategorySelected: ((TrackerCategory) -> Void)?
    
    // MARK: - Private
    
    private let viewModel: CategoryListViewModel
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("category", comment: "Category screen header")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.layer.masksToBounds = true
        return table
    }()
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(resource: .bgplaceholder))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("category_empty_label", comment: "Category empty label")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("category_create_button", comment: "Add category button"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypBlack
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    
    init(viewModel: CategoryListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupLayout()
        setupTable()
        setupActions()
        bindViewModel()
        
        viewModel.reload()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyImageView)
        view.addSubview(emptyLabel)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -24),
            
            emptyImageView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -20),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: "CategoryCell")
    }
    
    private func setupActions() {
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.onCategoriesChanged = { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadData()
            self.updateEmptyState()
        }
        
        viewModel.onCategorySelected = { [weak self] category in
            self?.onCategorySelected?(category)
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = viewModel.numberOfRows() == 0
        tableView.isHidden = isEmpty
        emptyImageView.isHidden = !isEmpty
        emptyLabel.isHidden = !isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func addTapped() {
        let newCategoryVC = NewCategoryViewController()
        newCategoryVC.onCreateCategory = { [weak self] title in
            self?.viewModel.addCategory(title: title)
        }
        
        let nav = UINavigationController(rootViewController: newCategoryVC)
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CategoryListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let category   = viewModel.category(at: indexPath)
        let isSelected = viewModel.isSelected(at: indexPath)
        let isLast     = indexPath.row == viewModel.numberOfRows() - 1
        
        cell.configure(
            title: category.title,
            isSelected: isSelected,
            isLast: isLast
        )
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CategoryListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath)
        tableView.reloadData()
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        
        let count = viewModel.numberOfRows()
        let isFirst = indexPath.row == 0
        let isLast  = indexPath.row == count - 1
        
        let radius: CGFloat = 16
        var corners: UIRectCorner = []
        
        if isFirst { corners.insert([.topLeft, .topRight]) }
        if isLast  { corners.insert([.bottomLeft, .bottomRight]) }
        
        let path: UIBezierPath
        if corners.isEmpty {
            path = UIBezierPath(rect: cell.bounds)
        } else {
            path = UIBezierPath(
                roundedRect: cell.bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
        }
        
        let mask = CAShapeLayer()
        mask.frame = cell.bounds
        mask.path = path.cgPath
        cell.contentView.layer.mask = mask
    }
}
