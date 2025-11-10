

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
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        // Set a fallback image immediately
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray

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
}
