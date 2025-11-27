import UIKit
import CoreData

final class StatisticsViewController: UIViewController {
    
    // MARK: - Dependencies
    
    private let recordStore = TrackerRecordStore()
    private let maskShape = CAShapeLayer()
    
    // MARK: - UI
    
    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.systemRed.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemGreen.cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        return g
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("statistics_title", comment: "Statistics screen title")
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emptyEmojiImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(resource: .cryEmoji))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyTextLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("statistics_empty_label", comment: "Nothing to analyse yet")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let v = UIScrollView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alwaysBounceVertical = true
        return v
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let bestPeriodCard   = StatCardView()
    private let idealDaysCard    = StatCardView()
    private let completedCard    = StatCardView()
    private let averageCard      = StatCardView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadStatistics()
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        view.addSubview(emptyEmojiImage)
        view.addSubview(emptyTextLabel)
        
        scrollView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(bestPeriodCard)
        contentStack.addArrangedSubview(idealDaysCard)
        contentStack.addArrangedSubview(completedCard)
        contentStack.addArrangedSubview(averageCard)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
            
            bestPeriodCard.heightAnchor.constraint(equalToConstant: 90),
            idealDaysCard.heightAnchor.constraint(equalToConstant: 90),
            completedCard.heightAnchor.constraint(equalToConstant: 90),
            averageCard.heightAnchor.constraint(equalToConstant: 90),
            
            emptyEmojiImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyEmojiImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            emptyEmojiImage.widthAnchor.constraint(equalToConstant: 80),
            emptyEmojiImage.heightAnchor.constraint(equalToConstant: 80),
            
            emptyTextLabel.topAnchor.constraint(equalTo: emptyEmojiImage.bottomAnchor, constant: 8),
            emptyTextLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emptyTextLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        bestPeriodCard.configure(title: NSLocalizedString("stats_best_period", comment: "Best period"))
        idealDaysCard.configure(title: NSLocalizedString("stats_ideal_days", comment: "Ideal days"))
        completedCard.configure(title: NSLocalizedString("stats_completed_trackers", comment: "Completed trackers"))
        averageCard.configure(title: NSLocalizedString("stats_average_value", comment: "Average value"))
        
        bestPeriodCard.setGradientColors([.colorSelection1, .colorSelection9, .colorSelection3])
        idealDaysCard.setGradientColors([.colorSelection1, .colorSelection9, .colorSelection3])
        completedCard.setGradientColors([.colorSelection1, .colorSelection9, .colorSelection3])
        averageCard.setGradientColors([.colorSelection1, .colorSelection9, .colorSelection3])
        
    }
    
    // MARK: - Data / Logic
    
    private func reloadStatistics() {
        let coreRecords = recordStore.getAll()
        
        guard !coreRecords.isEmpty else {
            showEmptyState(true)
            return
        }
        
        showEmptyState(false)
        
        let stats = calculateStats(from: coreRecords)
        
        bestPeriodCard.setValue(stats.bestPeriod)
        idealDaysCard.setValue(stats.idealDays)
        completedCard.setValue(stats.completedTotal)
        averageCard.setValue(stats.averagePerDay)
    }
    
    private func showEmptyState(_ isEmpty: Bool) {
        emptyEmojiImage.isHidden = !isEmpty
        emptyTextLabel.isHidden = !isEmpty
        scrollView.isHidden = isEmpty
    }
    
    private func calculateStats(from records: [TrackerRecordCoreData]) -> (bestPeriod: Int,
                                                                           idealDays: Int,
                                                                           completedTotal: Int,
                                                                           averagePerDay: Int) {
        let calendar = Calendar.current
        
        var recordsByDay: [Date: Set<UUID>] = [:]
        var allTrackerIds = Set<UUID>()
        
        for record in records {
            guard
                let date = record.date,
                let id = record.trackerId
            else { continue }
            
            let day = calendar.startOfDay(for: date)
            
            var set = recordsByDay[day] ?? Set<UUID>()
            set.insert(id)
            recordsByDay[day] = set
            allTrackerIds.insert(id)
        }
        
        let completedTotal = records.count
        
        let sortedDays = recordsByDay.keys.sorted()
        
        var bestPeriod = 0
        var currentStreak = 0
        var previousDay: Date?
        
        for day in sortedDays {
            if let prev = previousDay,
               let next = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(day, inSameDayAs: next) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            bestPeriod = max(bestPeriod, currentStreak)
            previousDay = day
        }
        
        let totalTrackersCount = allTrackerIds.count
        var idealDays = 0
        if totalTrackersCount > 0 {
            for (_, ids) in recordsByDay {
                if ids.count == totalTrackersCount {
                    idealDays += 1
                }
            }
        }
        
        let daysCount = max(1, recordsByDay.keys.count)
        let averageRaw = Double(completedTotal) / Double(daysCount)
        let averagePerDay = Int(round(averageRaw))
        
        return (bestPeriod, idealDays, completedTotal, averagePerDay)
    }
}

private final class StatCardView: UIView {
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let container: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint   = CGPoint(x: 1, y: 0.5)
        return g
    }()
    
    private let maskShape = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    private func setup() {
        addSubview(container)
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)
        
        layer.masksToBounds = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        container.layer.addSublayer(gradientLayer)
        gradientLayer.mask = maskShape
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = container.bounds
        
        let path = UIBezierPath(
            roundedRect: container.bounds.insetBy(dx: 1, dy: 1),
            cornerRadius: 16
        )
        
        maskShape.path = path.cgPath
        maskShape.lineWidth = 1
        maskShape.fillColor = UIColor.clear.cgColor
        maskShape.strokeColor = UIColor.black.cgColor
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
    
    func setValue(_ value: Int) {
        valueLabel.text = "\(value)"
    }
    
    func setGradientColors(_ colors: [UIColor]) {
        gradientLayer.colors = colors.map { $0.cgColor }
    }
}
