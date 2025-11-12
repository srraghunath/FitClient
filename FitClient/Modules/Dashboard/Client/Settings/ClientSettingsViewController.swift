//
//  ClientSettingsViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class ClientSettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
}
