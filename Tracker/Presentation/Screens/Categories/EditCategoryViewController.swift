import UIKit

final class EditCategoryViewController: UIViewController {

    // MARK: - Public
    var onSave: ((String) -> Void)?

    // MARK: - Private
    private let initialName: String

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("edit_category_title",
                                       comment: "Edit category title")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = NSLocalizedString("new_category_text_field",
                                           comment: "Category name placeholder")
        tf.backgroundColor = UIColor(resource: .ypBackground)
        tf.layer.cornerRadius = 16
        tf.layer.masksToBounds = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.clearButtonMode = .whileEditing
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("done", comment: "Done"), for: .normal)
        button.setTitleColor(.ypWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .ypBlack
        return button
    }()

    // MARK: - Init

    init(initialName: String) {
        self.initialName = initialName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupLayout()
        setupActions()

        nameTextField.delegate = self
        nameTextField.text = initialName
        nameTextField.becomeFirstResponder()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(nameTextField)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                               constant: 38),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                 constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                               constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Actions

    private func setupActions() {
        doneButton.addTarget(self,
                             action: #selector(doneTapped),
                             for: .touchUpInside)
        nameTextField.addTarget(self,
                                action: #selector(textChanged),
                                for: .editingChanged)
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    @objc private func doneTapped() {
        let text = nameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        onSave?(text)
        dismiss(animated: true)
    }

    @objc private func textChanged() {
        let text = nameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        doneButton.isEnabled = !text.isEmpty

        UIView.animate(withDuration: 0.2) {
            self.doneButton.backgroundColor = text.isEmpty ? .ypGray : .ypBlack
        }
    }
}

// MARK: - UITextFieldDelegate

extension EditCategoryViewController: UITextFieldDelegate {}
