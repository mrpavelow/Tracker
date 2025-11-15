import UIKit

protocol TrackerCellDelegate: AnyObject {
    func didTapPlusButton(in cell: TrackerCell)
}

final class TrackerCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCell"
    
    weak var delegate: TrackerCellDelegate?
    private var tracker: Tracker?
    
    private let cardView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let emojiBg = UIView()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with tracker: Tracker, completedToday: Bool, completedCount: Int) {
        // Основные данные
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.name
        cardView.backgroundColor = tracker.color
        countLabel.text = "\(completedCount) дней"
        
        // Кнопка плюс/галочка
        let imageName = completedToday ? "checkMark" : "plusButton"
        let image = UIImage(named: imageName)
        plusButton.setImage(image, for: .normal)
        plusButton.tintColor = tracker.color
        
        // Управление доступностью кнопки
        if completedToday {
            plusButton.alpha = 0.3
            plusButton.isUserInteractionEnabled = false
        } else {
            plusButton.alpha = 1.0
            plusButton.isUserInteractionEnabled = true
        }
    }
    
    @objc private func didTapPlus() {
        delegate?.didTapPlusButton(in: self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.isUserInteractionEnabled = false
        
        emojiBg.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emojiBg.layer.cornerRadius = 12
        emojiBg.translatesAutoresizingMaskIntoConstraints = false
        
        emojiLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.textColor = .label
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(cardView)
        cardView.addSubview(emojiBg)
        cardView.addSubview(emojiLabel)
        cardView.addSubview(titleLabel)
        contentView.addSubview(plusButton)
        contentView.addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            // Карточка
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            // Фон эмодзи
            emojiBg.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiBg.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiBg.heightAnchor.constraint(equalToConstant: 24),
            emojiBg.widthAnchor.constraint(equalToConstant: 24),
            
            // Текст эмодзи
            emojiLabel.heightAnchor.constraint(equalToConstant: 16),
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBg.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBg.centerYAnchor),
            
            // Название
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            // Кнопка + под карточкой
            plusButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            plusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            plusButton.widthAnchor.constraint(equalToConstant: 34),
            plusButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Счётчик
            countLabel.centerYAnchor.constraint(equalTo: plusButton.centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            
            // Низ ячейки
            contentView.bottomAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 12)
        ])
    }
}


