//
//  ClientWorkoutsViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class ClientWorkoutsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        title = "Workouts"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
}
