import UIKit

let onboardingSeenKey = "hasSeenOnboarding"

final class OnboardingViewController: UIPageViewController {
    
    // MARK: - Страницы
    
    private let pagesData: [OnboardingPage] = [
        OnboardingPage(
            backgroundImageName: "onbBlue",
            text: "Отслеживайте только \nто, что хотите"
        ),
        OnboardingPage(
            backgroundImageName: "onbRed",
            text: "Даже если это \nне литры воды и йога"
        )
    ]
    
    private lazy var pages: [OnboardingPageViewController] = {
        pagesData.map { OnboardingPageViewController(page: $0) }
    }()
    
    private var currentIndex: Int = 0 {
        didSet {
            pageControl.currentPage = currentIndex
        }
    }
    
    // MARK: - UI
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .black
        pc.pageIndicatorTintColor = .lightGray
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Вот это технологии!", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .ypBlack
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    
    init() {
        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        view.backgroundColor = .systemBackground
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: false, completion: nil)
        }
        
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        
        setupLayout()
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(pageControl)
        view.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            actionButton.heightAnchor.constraint(equalToConstant: 60),
            
            pageControl.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        UserDefaults.standard.set(true, forKey: onboardingSeenKey)
        UserDefaults.standard.synchronize()
        
        dismiss(animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let current = viewController as? OnboardingPageViewController,
              let index = pages.firstIndex(where: { $0 === current }),
              index > 0 else {
            return nil
        }
        
        return pages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let current = viewController as? OnboardingPageViewController,
              let index = pages.firstIndex(where: { $0 === current }),
              index < pages.count - 1 else {
            return nil
        }
        
        return pages[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        
        guard completed,
              let visible = viewControllers?.first as? OnboardingPageViewController,
              let index = pages.firstIndex(where: { $0 === visible }) else {
            return
        }
        
        currentIndex = index
    }
}
