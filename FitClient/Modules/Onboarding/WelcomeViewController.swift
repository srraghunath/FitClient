//
//  WelcomeViewController.swift
//  FitClient
//
//  Created by admin8 on 2025-01-14.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Navigation bar is hidden for welcome screen
        // UI elements are fully configured in storyboard
    }

}
