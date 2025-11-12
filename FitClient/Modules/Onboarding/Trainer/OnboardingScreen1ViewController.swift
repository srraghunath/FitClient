

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
    
    func setupLabelsAndButton() {
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
    
    func setupUI() {
        view.backgroundColor = .black
        
        setupLabelsAndButton()
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if let pageVC = parent as? OnboardingPageViewController {
            if pageVC.pages.count > 1 {
                pageVC.setViewControllers([pageVC.pages[1]], direction: .forward, animated: true, completion: nil)
                pageVC.pageControl.currentPage = 1
            }
        }
    }
}
