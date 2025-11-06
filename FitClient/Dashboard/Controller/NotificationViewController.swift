//
//  NotificationViewController.swift
//  FitClient
//
//  Created by admin8 on 06/11/25.
//

import UIKit

class NotificationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .primaryGreen
    }
}
