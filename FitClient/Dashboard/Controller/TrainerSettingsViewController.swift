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
  
        // Set title
        title = "Settings"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
    }
}
