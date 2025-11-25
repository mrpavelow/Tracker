import UIKit

final class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureAppearance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let seen = UserDefaultsService.shared.hasSeenOnboarding
        guard !seen else { return }

        let onboarding = OnboardingViewController()
        onboarding.modalPresentationStyle = .fullScreen
        present(onboarding, animated: true)
    }
    
    private func setupTabs() {
        let trackersVC = TrackersViewController()
        let trackersNav = UINavigationController(rootViewController: trackersVC)
        trackersNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("trackers_tb_label", comment: "Trackers label in Tabbar"),
            image: UIImage(named: "trackers"),
            tag: 0
        )
        
        let statsVC = StatisticsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)
        statsNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("statistics_tb_label", comment: "Statistics label in Tabbar"),
            image: UIImage(named: "stats"),
            tag: 1
        )
        viewControllers = [trackersNav, statsNav]
    }
    
    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemBlue
    }
}
