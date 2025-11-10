

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
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Setup description
        descriptionLabel.text = "Easily update workout, cardio, diet and sleep goals."
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
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Load Sign In screen with Navigation Controller
        let signInVC = SignInViewController(nibName: "SignInViewController", bundle: nil)
        let navigationController = UINavigationController(rootViewController: signInVC)
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = .black
        navigationController.navigationBar.tintColor = .primaryGreen
        navigationController.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        present(navigationController, animated: true, completion: nil)
    }
}
