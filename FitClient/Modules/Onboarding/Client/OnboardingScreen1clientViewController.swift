//
//  OnboardingScreen1clientViewController.swift
//  FitClient
//
//  Created by admin6 on 12/11/25.
//

import UIKit

class OnboardingScreen1clientViewController: UIViewController {
    
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
        titleLabel.text = "Track progress and create plans"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Setup description
        descriptionLabel.text = "Easily track your client's progress and create personalized workout and diet plans."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .textPrimary
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Setup button
        nextButton.applyPrimaryStyle(title: "Next")
        
        // Setup image
        imageView.image = UIImage(named: "Onboarding1")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if let pageVC = parent as? OnboardingPageClientViewController {
            if pageVC.pages.count > 1 {
                pageVC.setViewControllers([pageVC.pages[1]], direction: .forward, animated: true, completion: nil)
                pageVC.pageControl.currentPage = 1
            }
        }
    }
}
