

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // Tab bar appearance
        tabBar.backgroundColor = .tabBarBackground
        tabBar.barTintColor = .tabBarBackground
        tabBar.isTranslucent = false
        tabBar.tintColor = .primaryGreen
        tabBar.unselectedItemTintColor = .textTertiary
        
        // Border line at top
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor.tabBarBackground.cgColor
        borderLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1)
        tabBar.layer.addSublayer(borderLayer)
    }
    
    private func setupViewControllers() {
        // Sessions Tab
        let sessionsVC = TrainerSessionsViewController(nibName: "TrainerSessionsViewController", bundle: nil)
        let sessionsNav = UINavigationController(rootViewController: sessionsVC)
        sessionsNav.view.backgroundColor = .black
        sessionsNav.navigationBar.barTintColor = .black
        sessionsNav.navigationBar.backgroundColor = .black
        sessionsNav.tabBarItem = UITabBarItem(
            title: "Sessions",
            image: UIImage(systemName: "calendar.badge.clock"),
            selectedImage: UIImage(systemName: "calendar.badge.clock")
        )
        
        // Clients Tab
        let clientsVC = TrainerClientsViewController(nibName: "TrainerClientsViewController", bundle: nil)
        let clientsNav = UINavigationController(rootViewController: clientsVC)
        clientsNav.view.backgroundColor = .black
        clientsNav.navigationBar.barTintColor = .black
        clientsNav.navigationBar.backgroundColor = .black
        clientsNav.tabBarItem = UITabBarItem(
            title: "Clients",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2")
        )
        
        // Settings Tab
        let settingsVC = TrainerSettingsViewController(nibName: "TrainerSettingsViewController", bundle: nil)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.view.backgroundColor = .black
        settingsNav.navigationBar.barTintColor = .black
        settingsNav.navigationBar.backgroundColor = .black
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape")
        )
        
        // Set view controllers
        viewControllers = [sessionsNav, clientsNav, settingsNav]
    }
}
