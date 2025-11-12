//
//  ClientTabBarController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class ClientTabBarController: UITabBarController {
    
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
        // Dashboard Tab - HOME with house icon
        let dashboardVC = DashboardViewController(nibName: "DashboardViewController", bundle: nil)
        let dashboardNav = UINavigationController(rootViewController: dashboardVC)
        dashboardNav.view.backgroundColor = .black
        dashboardNav.navigationBar.barTintColor = .black
        dashboardNav.navigationBar.backgroundColor = .black
        dashboardNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        // Workouts Tab - PROGRESS with chart icon
        let progressVC = ClientProgressViewController(nibName: "ClientProgressViewController", bundle: nil)
        let progressNav = UINavigationController(rootViewController: progressVC)
        progressNav.view.backgroundColor = .black
        progressNav.navigationBar.barTintColor = .black
        progressNav.navigationBar.backgroundColor = .black
        progressNav.tabBarItem = UITabBarItem(
            title: "Progress",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        
        // Chat Tab - CHAT with message icon
        let chatVC = ClientWorkoutsViewController(nibName: "ClientWorkoutsViewController", bundle: nil) // Placeholder
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.view.backgroundColor = .black
        chatNav.navigationBar.barTintColor = .black
        chatNav.navigationBar.backgroundColor = .black
        chatNav.tabBarItem = UITabBarItem(
            title: "Chat",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )
        
        // Settings Tab - SETTINGS with gear icon
        let settingsVC = ClientSettingsViewController(nibName: "ClientSettingsViewController", bundle: nil)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.view.backgroundColor = .black
        settingsNav.navigationBar.barTintColor = .black
        settingsNav.navigationBar.backgroundColor = .black
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        
        // Set view controllers in correct order: Home, Progress, Chat, Settings
        viewControllers = [dashboardNav, progressNav, chatNav, settingsNav]
    }
}
