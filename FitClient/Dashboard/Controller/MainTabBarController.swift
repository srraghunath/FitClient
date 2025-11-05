//
//  MainTabBarController.swift
//  FitClient
//
//  Created by admin8 on 05/11/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // Tab bar appearance
        tabBar.backgroundColor = UIColor(red: 0.129, green: 0.129, blue: 0.129, alpha: 1.0)
        tabBar.barTintColor = UIColor(red: 0.129, green: 0.129, blue: 0.129, alpha: 1.0)
        tabBar.isTranslucent = false
        tabBar.tintColor = UIColor(red: 0.682, green: 0.996, blue: 0.078, alpha: 1.0) // Lime green
        tabBar.unselectedItemTintColor = UIColor(red: 0.843, green: 0.800, blue: 0.784, alpha: 1.0) // Light brown
        
        // Border line at top
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.129, green: 0.129, blue: 0.129, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1)
        tabBar.layer.addSublayer(borderLayer)
    }
    
    private func setupViewControllers() {
        // Sessions Tab
        let sessionsVC = TrainerSessionsViewController(nibName: "TrainerSessionsViewController", bundle: nil)
        let sessionsNav = UINavigationController(rootViewController: sessionsVC)
        sessionsNav.tabBarItem = UITabBarItem(
            title: "Sessions",
            image: UIImage(systemName: "calendar.badge.clock"),
            selectedImage: UIImage(systemName: "calendar.badge.clock")
        )
        
        // Clients Tab
        let clientsVC = UIViewController() // TODO: Replace with ClientsViewController when implemented
        clientsVC.view.backgroundColor = .black
        let clientsNav = UINavigationController(rootViewController: clientsVC)
        clientsNav.tabBarItem = UITabBarItem(
            title: "Clients",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2")
        )
        
        // Settings Tab
        let settingsVC = TrainerSettingsViewController(nibName: "TrainerSettingsViewController", bundle: nil)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape")
        )
        
        // Set view controllers
        viewControllers = [sessionsNav, clientsNav, settingsNav]
    }
}
