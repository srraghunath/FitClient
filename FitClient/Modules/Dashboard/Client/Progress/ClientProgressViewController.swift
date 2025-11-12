//
//  ClientProgressViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class ClientProgressViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        title = "Progress"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
}
