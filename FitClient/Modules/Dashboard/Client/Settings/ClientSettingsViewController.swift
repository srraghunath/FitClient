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
    
    private let settings: [SettingsItem] = [
        SettingsItem(
            title: "Profile",
            subtitle: "View and edit your profile",
            icon: "user.fill",
            iconBackgroundColor: .clear,
            isProfileItem: true
        ),
        SettingsItem(
            title: "Notifications",
            subtitle: "Manage your notification preferences",
            icon: "bell.fill",
            iconBackgroundColor: UIColor(red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
        ),
        SettingsItem(
            title: "Help & Support",
            subtitle: "Get help and support",
            icon: "questionmark.circle.fill",
            iconBackgroundColor: UIColor(red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
        ),
        SettingsItem(
            title: "Report a Bug",
            subtitle: "Help us fix it",
            icon: "ant.fill",
            iconBackgroundColor: UIColor(red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
        ),
        SettingsItem(
            title: "Logout",
            subtitle: nil,
            icon: "arrow.right.square.fill",
            iconBackgroundColor: UIColor(red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        // Get logged-in user ID from UserDefaults
        if let userEmail = UserDefaults.standard.string(forKey: "userEmail") {
            let clientId = "client_001" // This would normally come from auth
            
            // Use DataService to load profile
            DataService.shared.loadClientProfile(forClientId: clientId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        self?.userProfile = profile
                        self?.settingsTableView.reloadData()
                    case .failure(let error):
                        print("Failed to load profile: \(error)")
                    }
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
        settingsTableView.estimatedRowHeight = 72
        settingsTableView.rowHeight = UITableView.automaticDimension
        
        settingsTableView.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ClientSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }
        cell.configure(with: settings[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = settings[indexPath.row]
        
        switch indexPath.row {
        case 0:
            let editVC = ClientSettingsEditProfileViewController(nibName: "ClientSettingsEditProfileViewController", bundle: nil)
            navigationController?.pushViewController(editVC, animated: true)
        case 1:
            let notificationVC = ClientNotificationViewController(nibName: "ClientNotificationViewController", bundle: nil)
            navigationController?.pushViewController(notificationVC, animated: true)
        case 2:
            let helpVC = ClientHelpViewController(nibName: "ClientHelpViewController", bundle: nil)
            navigationController?.pushViewController(helpVC, animated: true)
        case 3:
            // Reuse Help screen's Submit a Request section
            let helpVC = ClientHelpViewController(nibName: "ClientHelpViewController", bundle: nil)
            navigationController?.pushViewController(helpVC, animated: true)
        case 4:
            print("Logout tapped")
            handleLogout()
        default:
            break
        }
    }
    
    private func handleLogout() {
        // Clear user defaults
        UserDefaults.standard.set(false, forKey: "isClient")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        
        // Navigate back to sign in
        let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
        window?.windows.first?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
    }
}

// MARK: - Settings Item Model

struct SettingsItem {
    let title: String
    let subtitle: String?
    let icon: String
    let iconBackgroundColor: UIColor
    var isProfileItem: Bool = false
}

// MARK: - Settings Cell

class SettingsCell: UITableViewCell {
    
    private let containerView = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let profileImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        profileImageView.layer.cornerRadius = 28
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Title Label
        titleLabel.font = UIFont(name: "SFProDisplay-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.font = UIFont(name: "SFProDisplay-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor(red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            containerView.heightAnchor.constraint(equalToConstant: 72),
            
            // Icon Container
            iconContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            // Icon Image View
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Profile Image View
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 56),
            profileImageView.heightAnchor.constraint(equalToConstant: 56),
            
            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // Subtitle Label
            subtitleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 21)
        ])
    }
    
    func configure(with item: SettingsItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
        
        if item.isProfileItem {
            // Show profile image
            profileImageView.isHidden = false
            iconContainer.isHidden = true
            
            // Try to load profile image from assets
            if let profileImageName = UserDefaults.standard.string(forKey: "userProfileImage"),
               let profileImage = UIImage(named: profileImageName) {
                profileImageView.image = profileImage
                profileImageView.contentMode = .scaleAspectFill
            } else if let profileImage = UIImage(named: "profile1") {
                profileImageView.image = profileImage
                profileImageView.contentMode = .scaleAspectFill
            } else {
                // Fallback: Create placeholder with initials
                profileImageView.backgroundColor = UIColor(red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
                let initials = getUserInitials()
                if profileImageView.subviews.isEmpty {
                    addInitialsToImageView(initials)
                }
            }
        } else {
            // Show icon
            profileImageView.isHidden = true
            iconContainer.isHidden = false
            iconContainer.backgroundColor = item.iconBackgroundColor
            iconImageView.image = UIImage(systemName: item.icon)
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
        label.font = UIFont(name: "SFProDisplay-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        profileImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])
    }
}
