//
//  OnboardingScreen2clientViewController.swift
//  FitClient
//
//  Created by admin6 on 12/11/25.
//

import UIKit

class OnboardingScreen2clientViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        // Setup title
        titleLabel.text = "Stay on track"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Setup description
        descriptionLabel.text = "Get reminders for water, cardio, workout, diet and sleep."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .textPrimary
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Setup button
        nextButton.applyPrimaryStyle(title: "Next")
        
        // Setup image
        imageView.image = UIImage(named: "Onboarding2")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // Page view controller will handle navigation
        if let pageVC = parent as? OnboardingPageClientViewController {
            if pageVC.pages.count > 2 {
                pageVC.setViewControllers([pageVC.pages[2]], direction: .forward, animated: true, completion: nil)
                pageVC.pageControl.currentPage = 2
            }
        }
    }
}
