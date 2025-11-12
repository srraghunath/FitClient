//
//  OnboardingScreen3clientViewController.swift
//  FitClient
//
//  Created by admin6 on 12/11/25.
//

import UIKit

class OnboardingScreen3clientViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        // Setup title
        titleLabel.text = "Stay connected"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Setup description
        descriptionLabel.text = "Message your trainer in-app and follow their guided plans."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .textPrimary
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Setup button
        getStartedButton.applyPrimaryStyle(title: "Get Started")
        
        // Setup image
        imageView.image = UIImage(named: "Onboarding3")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }
    
    @IBAction func getStartedButtonTapped(_ sender: UIButton) {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedClientOnboarding")
        
        // Navigate to Sign In
        let signInVC = SignInClientViewController(nibName: "SignInClientViewController", bundle: nil)
        let navController = UINavigationController(rootViewController: signInVC)
        navController.modalPresentationStyle = .fullScreen
        navController.modalTransitionStyle = .crossDissolve
        present(navController, animated: true, completion: nil)
    }
}
