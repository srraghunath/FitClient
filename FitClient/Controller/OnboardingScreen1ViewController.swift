//
//  OnboardingScreen1ViewController.swift
//  FitClient
//
//  Created by admin41 on 03/11/25.
//

import UIKit

class OnboardingScreen1ViewController: UIViewController {
    
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
        titleLabel.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Setup description
        descriptionLabel.text = "Easily track your client's progress and create personalized workout and diet plans."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Setup button
        nextButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nextButton.layer.cornerRadius = 24
        
        // Setup image
        imageView.image = UIImage(named: "Onboarding1")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // Page view controller will handle navigation
        if let pageVC = parent as? OnboardingPageViewController {
            if pageVC.pages.count > 1 {
                pageVC.setViewControllers([pageVC.pages[1]], direction: .forward, animated: true, completion: nil)
                pageVC.pageControl.currentPage = 1
            }
        }
    }
}
