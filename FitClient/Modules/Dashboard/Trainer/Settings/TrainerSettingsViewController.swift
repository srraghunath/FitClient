

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
        loadProfileImage()
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
        
        print("[TrainerSettings] Fetching profile image from Supabase...")
        TrainerService.shared.fetchTrainerProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let trainerProfile):
                    if let urlString = trainerProfile.profileImageURL,
                       let url = URL(string: urlString) {
                        print("[TrainerSettings] Loading profile image from URL: \(urlString)")
                        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                            if let error {
                                print("[TrainerSettings] Image download failed: \(error)")
                            }

                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self?.profileImageView.image = image
                                    if let imageView = self?.profileImageView {
                                        let size = min(imageView.bounds.width, imageView.bounds.height)
                                        imageView.layer.cornerRadius = size / 2.0
                                    }
                                }
                            } else {
                                print("[TrainerSettings] No image data; using placeholder")
                                self?.setInitialsPlaceholder(name: trainerProfile.fullName)
                            }
                        }.resume()
                    } else {
                        print("[TrainerSettings] No profile image URL; using initials placeholder")
                        self?.setInitialsPlaceholder(name: trainerProfile.fullName)
                    }
                case .failure(let error):
                    print("[TrainerSettings] Failed to fetch profile: \(error)")
                    self?.setInitialsPlaceholder(name: "Trainer")
                }
            }
        }
    }

    private func setInitialsPlaceholder(name: String) {
        let initials = name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0) }
            .joined()
            .uppercased()

        let label = UILabel(frame: profileImageView.bounds)
        label.backgroundColor = .primaryGreen
        label.textColor = .black
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.text = initials.isEmpty ? "T" : initials

        UIGraphicsBeginImageContextWithOptions(profileImageView.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        profileImageView.image = image
        let size = min(profileImageView.bounds.width, profileImageView.bounds.height)
        profileImageView.layer.cornerRadius = size / 2.0
    }
    
    // @IBAction func subscriptionTapped(_ sender: Any) {
    //     let subscriptionVC = SubscriptionViewController(nibName: "SubscriptionViewController", bundle: nil)
    //     navigationController?.pushViewController(subscriptionVC, animated: true)
    // }
    
    // @IBAction func notificationTapped(_ sender: Any) {
    //     let notificationVC = NotificationViewController(nibName: "NotificationViewController", bundle: nil)
    //     navigationController?.pushViewController(notificationVC, animated: true)
    // }
    
    @IBAction func helpTapped(_ sender: Any) {
        let helpVC = HelpViewController(nibName: "HelpViewController", bundle: nil)
        navigationController?.pushViewController(helpVC, animated: true)
    }
    
    @IBAction func editProfileTapped(_ sender: Any) {
        let editProfileVC = TrainerSettingsEditProfileViewController(nibName: "TrainerSettingsEditProfileViewController", bundle: nil)
        navigationController?.pushViewController(editProfileVC, animated: true)
    }

    @IBAction func logoutTapped(_ sender: Any) {
        handleLogout()
    }

    @IBAction func deleteAccountTapped(_ sender: Any) {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account? This action is permanent and all your trainer data will be lost forever.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Permanently", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })
        
        present(alert, animated: true)
    }
    
    private func performDeleteAccount() {
        AuthService.shared.deleteUserAccount { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAlert(message: "Error deleting account: \(error.localizedDescription)")
                    return
                }
                self?.navigateToWelcome()
            }
        }
    }
    
    private func handleLogout() {
        AuthService.shared.signOut { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAlert(message: "Error logging out: \(error.localizedDescription)")
                    return
                }
                self?.navigateToWelcome()
            }
        }
    }
    
    private func navigateToWelcome() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            window.makeKeyAndVisible()
        }
    }
}
