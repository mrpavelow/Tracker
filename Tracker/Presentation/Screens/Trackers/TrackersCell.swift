import UIKit

protocol TrackerCellDelegate: AnyObject {
    func didTapPlusButton(in cell: TrackerCell)
}

final class TrackerCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCell"
    
    weak var delegate: TrackerCellDelegate?
    private var tracker: Tracker?
    
    private lazy var cardView: UIView = {
        let card = UIView()
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = false
        return card
    }()
    
    private lazy var emojiBg: UIView = {
        let emojiBg = UIView()
        emojiBg.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emojiBg.layer.cornerRadius = 12
        emojiBg.translatesAutoresizingMaskIntoConstraints = false
        return emojiBg
    }()
    
    private lazy var emojiLabel: UILabel = {
        let emoji = UILabel()
        emoji.font = .systemFont(ofSize: 16, weight: .medium)
        emoji.translatesAutoresizingMaskIntoConstraints = false
        return emoji
    }()
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textColor = .white
        title.numberOfLines = 2
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    private lazy var countLabel: UILabel = {
        let count = UILabel()
        count.font = .systemFont(ofSize: 12, weight: .medium)
        count.textColor = .label
        count.translatesAutoresizingMaskIntoConstraints = false
        return count
    }()

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
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    func configure(with tracker: Tracker, completedToday: Bool, completedCount: Int) {
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.name
        cardView.backgroundColor = tracker.color
        countLabel.text = String(format: NSLocalizedString("days_completed", comment: ""), completedCount)
        
        let imageResource: ImageResource = completedToday ? .checkMark : .plusButton
        let image = UIImage(resource: imageResource)
        plusButton.setImage(image, for: .normal)
        plusButton.tintColor = tracker.color
        plusButton.alpha = completedToday ? 0.3 : 1.0
    }
    
    @objc private func didTapPlus() {
        AnalyticsService.track(
                    event: .click,
                    screen: .main,
                    item: .track
                )
        delegate?.didTapPlusButton(in: self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(emojiBg)
        cardView.addSubview(emojiLabel)
        cardView.addSubview(titleLabel)
        contentView.addSubview(plusButton)
        contentView.addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),

            emojiBg.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiBg.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiBg.heightAnchor.constraint(equalToConstant: 24),
            emojiBg.widthAnchor.constraint(equalToConstant: 24),

            emojiLabel.heightAnchor.constraint(equalToConstant: 16),
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBg.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBg.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            plusButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            plusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            plusButton.widthAnchor.constraint(equalToConstant: 34),
            plusButton.heightAnchor.constraint(equalToConstant: 34),

            countLabel.centerYAnchor.constraint(equalTo: plusButton.centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),

            contentView.bottomAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 12)
        ])
    }
}


