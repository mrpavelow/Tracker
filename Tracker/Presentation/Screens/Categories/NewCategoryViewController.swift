import UIKit

final class NewCategoryViewController: UIViewController {
    
    // MARK: - Public
    var onCreateCategory: ((String) -> Void)?
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = (NSLocalizedString("new_category_screen_header", comment: "New category header"))
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var newCategoryTextField: UITextField = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .done, target: self, action: #selector(hideKeyboard))
        toolbar.items = [flex, done]
        let tf = UITextField()
        tf.inputAccessoryView = toolbar
        tf.placeholder = (NSLocalizedString("new_category_text_field", comment: "New category textfield"))
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
        button.setTitle(NSLocalizedString("done", comment: "Done button"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.backgroundColor = .ypGray
        return button
    }()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        setupLayout()
        setupActions()
        
        newCategoryTextField.delegate = self
        newCategoryTextField.becomeFirstResponder()
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(newCategoryTextField)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            newCategoryTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            newCategoryTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            newCategoryTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            newCategoryTextField.heightAnchor.constraint(equalToConstant: 75),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        newCategoryTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        let text = newCategoryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        
        onCreateCategory?(text)
        dismiss(animated: true)
    }
    
    @objc private func textChanged() {
        let text = newCategoryTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let enabled = !text.isEmpty
        
        doneButton.isEnabled = enabled
        UIView.animate(withDuration: 0.2) {
            self.doneButton.backgroundColor = enabled ? .ypBlack : .ypGray
        }
    }
}

// MARK: - UITextFieldDelegate

extension NewCategoryViewController: UITextFieldDelegate {}
