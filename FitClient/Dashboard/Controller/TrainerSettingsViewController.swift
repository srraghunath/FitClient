//
//  TrainerSettingsViewController.swift
//  FitClient
//
//  Created by admin8 on 05/11/25.
//

import UIKit

class TrainerSettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.backgroundColor = .black
        navigationController?.navigationBar.isTranslucent = false
        
        title = "Settings"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
    }
    
    @IBAction func subscriptionTapped(_ sender: Any) {
        let subscriptionVC = SubscriptionViewController(nibName: "SubscriptionViewController", bundle: nil)
        navigationController?.pushViewController(subscriptionVC, animated: true)
    }
}
