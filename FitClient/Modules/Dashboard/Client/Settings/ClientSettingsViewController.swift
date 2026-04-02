//
//  ClientSettingsViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class ClientSettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!

    private var userProfile: ClientProfile?
    private var profileImageURL: String?
    private var settings: [SettingsMenuItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadSettingsMenu()
        loadUserProfile()
    }

    private func loadSettingsMenu() {
        DataService.shared.loadSettingsMenuItems { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let menuData):
                    self?.settings = menuData.clientSettings
                    self?.settingsTableView.reloadData()
                case .failure(let error):
                    print("Failed to load settings menu: \(error)")
                }
            }
        }
    }

    private func loadUserProfile() {
        print("[ClientSettingsViewController] Loading user profile")

        // Load profile image from Supabase profile
        ClientProfileService.shared.fetchProfile { [weak self] result in
            print("[ClientSettingsViewController] FetchProfile result received")

            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    print("[ClientSettingsViewController] Profile loaded: \(profile)")
                    print(
                        "[ClientSettingsViewController] Profile image URL: \(profile.profileImageURL ?? "nil")"
                    )
                    self?.profileImageURL = profile.profileImageURL

                    // FIX: Update the profile cell directly
                    let profileIndexPath = IndexPath(row: 0, section: 0)
                    if let cell = self?.settingsTableView.cellForRow(at: profileIndexPath)
                        as? SettingsCell
                    {
                        cell.setProfileImageURL(profile.profileImageURL)
                        // Force reconfigure the cell
                        if let settings = self?.settings, settings.count > 0 {
                            cell.configure(with: settings[0])
                        }
                    }

                case .failure(let error):
                    print(
                        "[ClientSettingsViewController] Failed to load profile from Supabase: \(error)"
                    )
                }

                // Keep existing local profile load for other settings data
                if UserDefaults.standard.string(forKey: "userEmail") != nil {
                    let clientId = "client_001"
                    DataService.shared.loadClientProfile(forClientId: clientId) {
                        [weak self] result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let profile):
                                print("[ClientSettingsViewController] Local profile loaded")
                                self?.userProfile = profile
                            case .failure(let error):
                                print(
                                    "[ClientSettingsViewController] Failed to load local profile: \(error)"
                                )
                            }
                        }
                    }
                } else {
                    print("[ClientSettingsViewController] No user email found")
                }
            }
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        navigationController?.navigationBar.isHidden = true
    }

    private func setupTableView() {
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        settingsTableView.separatorStyle = .none
        settingsTableView.rowHeight = 72

        settingsTableView.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ClientSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                as? SettingsCell
        else {
            return UITableViewCell()
        }
        let item = settings[indexPath.row]
        print(
            "[ClientSettingsViewController] Configuring cell at row \(indexPath.row) with item: \(item.id)"
        )
        print(
            "[ClientSettingsViewController] Profile image URL to pass: \(profileImageURL ?? "nil")")

        // FIX: Set the URL FIRST, then configure
        cell.setProfileImageURL(profileImageURL)
        cell.configure(with: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let settingsItem = settings[indexPath.row]

        switch settingsItem.id {
        case "profile":
            let editVC = ClientSettingsEditProfileViewController(
                nibName: "ClientSettingsEditProfileViewController", bundle: nil)
            navigationController?.pushViewController(editVC, animated: true)
        case "notifications":
            let notificationVC = ClientNotificationViewController(
                nibName: "ClientNotificationViewController", bundle: nil)
            navigationController?.pushViewController(notificationVC, animated: true)
        case "help":
            let helpVC = ClientHelpViewController(nibName: "ClientHelpViewController", bundle: nil)
            navigationController?.pushViewController(helpVC, animated: true)
        case "disconnect":
            promptDisconnectTrainer()
        case "logout":
            print("Logout tapped")
            handleLogout()
        case "deleteAccount":
            promptDeleteAccount()
        default:
            break
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

    private func promptDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account? This action is permanent and all your profile, progress, and trainer connections will be lost forever.",
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

    private func navigateToWelcome() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            window.makeKeyAndVisible()
        }
    }

    private func promptDisconnectTrainer() {
        let alert = UIAlertController(
            title: "Disconnect Trainer",
            message: "This will remove your trainer connection and delete shared sessions, chats, and activity data from the trainer's view. You will be signed out.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive) { [weak self] _ in
            self?.disconnectTrainer()
        })

        present(alert, animated: true)
    }

    private func disconnectTrainer() {
        Task { [weak self] in
            guard let self else { return }

            do {
                guard let role = try await AuthService.shared.resolveCurrentRole() else {
                    await MainActor.run {
                        self.showAlert(message: "Unable to verify your account. Please try again.")
                    }
                    return
                }

                guard case let .client(_, clientId, trainerId) = role else {
                    await MainActor.run {
                        self.showAlert(message: "Only clients can disconnect from a trainer.")
                    }
                    return
                }

                guard trainerId != nil else {
                    await MainActor.run {
                        self.showAlert(message: "You are not currently connected to a trainer.")
                    }
                    return
                }

                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    ClientService.shared.disconnectClientAndPurgeData(clientId: clientId) { error in
                        if let error { cont.resume(throwing: error) } else { cont.resume() }
                    }
                }

                await MainActor.run {
                    self.showAlert(title: "Disconnected", message: "Your trainer connection and shared data have been removed. You will be signed out.") {
                        self.handleLogout()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(message: "Failed to disconnect: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Settings Cell

// MARK: - Settings Cell

class SettingsCell: UITableViewCell {

    private let containerView = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let profileImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var remoteProfileImageURL: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Set corner radius after layout - profile image should be circle
        if !profileImageView.isHidden {
            let profileSize = min(profileImageView.bounds.width, profileImageView.bounds.height)
            profileImageView.layer.cornerRadius = profileSize / 2.0
        }
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        selectionStyle = .none

        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        // Icon Container (for icon background)
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 8
        iconContainer.clipsToBounds = true
        containerView.addSubview(iconContainer)

        // Icon Image View
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)

        // Profile Image View
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)

        // Title Label
        titleLabel.font =
            UIFont(name: "SFProDisplay-Medium", size: 16)
            ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(
            red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Subtitle Label
        subtitleLabel.font =
            UIFont(name: "SFProDisplay-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor(
            red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        // Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: 0),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            containerView.heightAnchor.constraint(equalToConstant: 72),

            // Icon Container
            iconContainer.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),

            // Icon Image View
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Profile Image View
            profileImageView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 56),
            profileImageView.heightAnchor.constraint(equalToConstant: 56),

            // Title Label
            titleLabel.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),

            // Subtitle Label
            subtitleLabel.leadingAnchor.constraint(
                equalTo: profileImageView.trailingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 21),
        ])
    }

    func configure(with item: SettingsMenuItem) {
        print("[SettingsCell] Configuring cell with item: \(item.id)")
        print("[SettingsCell] isProfileItem: \(item.isProfileItem ?? false)")

        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil

        if item.isProfileItem == true {
            // Show profile image
            profileImageView.isHidden = false
            iconContainer.isHidden = true

            // Ensure circle shape is applied
            DispatchQueue.main.async {
                let size = min(
                    self.profileImageView.bounds.width, self.profileImageView.bounds.height)
                self.profileImageView.layer.cornerRadius = size / 2.0
            }

            print("[SettingsCell] remoteProfileImageURL: \(remoteProfileImageURL ?? "nil")")

            // Check remote URL first
            if let remoteProfileImageURL, !remoteProfileImageURL.isEmpty {
                print("[SettingsCell] Remote URL found: \(remoteProfileImageURL)")
                if let url = URL(string: remoteProfileImageURL) {
                    print("[SettingsCell] Loading remote image from URL: \(url)")
                    loadRemoteImage(url)
                } else {
                    print("[SettingsCell] Invalid URL format: \(remoteProfileImageURL)")
                    setupPlaceholderImage()
                }
            }
            // Only fallback to local if remote fails
            else if let profileImageName = UserDefaults.standard.string(forKey: "userProfileImage")
            {
                print("[SettingsCell] Loading local profile image: \(profileImageName)")
                if let profileImage = UIImage(named: profileImageName) {
                    profileImageView.image = profileImage
                    profileImageView.contentMode = .scaleAspectFill
                    profileImageView.backgroundColor = .clear
                } else {
                    print("[SettingsCell] Local image not found: \(profileImageName)")
                    setupPlaceholderImage()
                }
            } else if let profileImage = UIImage(named: "profile1") {
                print("[SettingsCell] Loading default profile1 image")
                profileImageView.image = profileImage
                profileImageView.contentMode = .scaleAspectFill
                profileImageView.backgroundColor = .clear
            } else {
                print("[SettingsCell] No images found, setting up placeholder")
                // Fallback: Create placeholder with initials
                setupPlaceholderImage()
            }
        } else {
            // Show icon
            profileImageView.isHidden = true
            iconContainer.isHidden = false
            iconContainer.backgroundColor = item.iconBgColor
            let symbol = UIImage(systemName: item.icon) ?? UIImage(systemName: "exclamationmark.triangle.fill")
            iconImageView.image = symbol
        }
    }

    func setProfileImageURL(_ urlString: String?) {
        print("[SettingsCell] Setting profile image URL: \(urlString ?? "nil")")
        remoteProfileImageURL = urlString
    }

    private func loadRemoteImage(_ url: URL) {
        print("[SettingsCell] Starting remote image download from: \(url)")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("[SettingsCell] Failed to load remote image: \(error)")
                DispatchQueue.main.async {
                    self.setupPlaceholderImage()
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("[SettingsCell] HTTP Response status: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("[SettingsCell] No image data received")
                DispatchQueue.main.async {
                    self.setupPlaceholderImage()
                }
                return
            }

            print("[SettingsCell] Received image data: \(data.count) bytes")

            guard let image = UIImage(data: data) else {
                print("[SettingsCell] Failed to create UIImage from data")
                DispatchQueue.main.async {
                    self.setupPlaceholderImage()
                }
                return
            }

            DispatchQueue.main.async {
                print("[SettingsCell] Setting loaded image to profileImageView")
                self.profileImageView.image = image
                self.profileImageView.contentMode = .scaleAspectFill
                self.profileImageView.backgroundColor = .clear
                // Clear any initials if they exist
                self.profileImageView.subviews.forEach { $0.removeFromSuperview() }
            }
        }.resume()
    }

    private func setupPlaceholderImage() {
        print("[SettingsCell] Setting up placeholder image")

        // Fallback to local image or initials
        if let profileImage = UIImage(named: "profile1") {
            print("[SettingsCell] Using profile1 placeholder")
            profileImageView.image = profileImage
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.backgroundColor = .clear
        } else {
            print("[SettingsCell] Using initials placeholder")
            profileImageView.backgroundColor = UIColor(
                red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902,
                alpha: 1.0)
            let initials = getUserInitials()
            print("[SettingsCell] Initials: \(initials)")
            if profileImageView.subviews.isEmpty {
                addInitialsToImageView(initials)
            }
        }
    }

    private func getUserInitials() -> String {
        if let email = UserDefaults.standard.string(forKey: "userEmail") {
            let name = email.split(separator: "@").first?.prefix(1).uppercased() ?? "U"
            return String(name)
        }
        return "U"
    }

    private func addInitialsToImageView(_ initials: String) {
        let label = UILabel()
        label.text = initials
        label.font =
            UIFont(name: "SFProDisplay-Bold", size: 20)
            ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        profileImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
        ])
    }
}
