

import UIKit

class TrainerSettingsViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadProfileImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.backgroundColor = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .primaryGreen
        
        title = "Settings"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black
    }
    
    private func loadProfileImage() {
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.primaryGreen.cgColor
        
        // Set cornerRadius in layoutSubviews and after image loads
        DispatchQueue.main.async {
            let size = min(self.profileImageView.bounds.width, self.profileImageView.bounds.height)
            self.profileImageView.layer.cornerRadius = size / 2.0
        }
        
        // Load trainer data and profile image
        /*
        DataService.shared.loadTrainer { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let trainer):
                    // Load profile image from URL
                    if let url = URL(string: trainer.profileImage) {
                        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self?.profileImageView.image = image
                                    // Set cornerRadius after image loads
                                    self?.profileImageView.layer.cornerRadius = (self?.profileImageView.bounds.width ?? 0) / 2.0
                                }
                            }
                        }.resume()
                    }
                    self?.nameLabel.text = trainer.name
                    self?.emailLabel.text = trainer.email
                case .failure(let error):
                    print("Failed to load trainer data: \(error)")
                }
            }
        }
        */
    }
    
    @IBAction func subscriptionTapped(_ sender: Any) {
        let subscriptionVC = SubscriptionViewController(nibName: "SubscriptionViewController", bundle: nil)
        navigationController?.pushViewController(subscriptionVC, animated: true)
    }
    
    @IBAction func notificationTapped(_ sender: Any) {
        let notificationVC = NotificationViewController(nibName: "NotificationViewController", bundle: nil)
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    @IBAction func helpTapped(_ sender: Any) {
        let helpVC = HelpViewController(nibName: "HelpViewController", bundle: nil)
        navigationController?.pushViewController(helpVC, animated: true)
    }
    
    @IBAction func editProfileTapped(_ sender: Any) {
        let editProfileVC = TrainerSettingsEditProfileViewController(nibName: "TrainerSettingsEditProfileViewController", bundle: nil)
        navigationController?.pushViewController(editProfileVC, animated: true)
    }

    @IBAction func logoutTapped(_ sender: Any) {
        AuthService.shared.logout()

        // Navigate back to the initial screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let welcomeVC = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController")
        let navigationController = UINavigationController(rootViewController: welcomeVC)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
        window?.windows.first?.rootViewController = navigationController
    }
}
