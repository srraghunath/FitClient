//
//  OnboardingScreen3ViewController.swift
//  FitClient
//
//  Created by admin41 on 03/11/25.
//

import UIKit

class OnboardingScreen3ViewController: UIViewController {
    
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
        titleLabel.text = "Update schedule easily"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Setup description
        descriptionLabel.text = "Easily update workout, cardio, diet and sleep goals."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Setup button
        getStartedButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.setTitleColor(UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0), for: .normal)
        getStartedButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        getStartedButton.layer.cornerRadius = 24
        
        // Setup image
        imageView.image = UIImage(named: "Onboarding3")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }
    
    @IBAction func getStartedButtonTapped(_ sender: UIButton) {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Load and present Sign In screen
        let signInVC = SignInViewController(nibName: "SignInViewController", bundle: nil)
        signInVC.modalPresentationStyle = .fullScreen
        signInVC.modalTransitionStyle = .crossDissolve
        present(signInVC, animated: true, completion: nil)
    }
}
