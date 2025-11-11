//
//  WelcomeViewController.swift
//  FitClient
//
//  Created by admin8 on 2025-01-14.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var trainerButton: UIButton!
    @IBOutlet weak var clientButton: UIButton!

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
    
    // MARK: - Segue Preparation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "trainer-segue" {
            if let navController = segue.destination as? UINavigationController {
                let signInVC = SignInViewController(nibName: "SignInViewController", bundle: nil)
                navController.setViewControllers([signInVC], animated: false)
            }
        } else if segue.identifier == "client-segue" {
            if let navController = segue.destination as? UINavigationController {
                let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
                navController.setViewControllers([signUpVC], animated: false)
            }
        }
    }

}
