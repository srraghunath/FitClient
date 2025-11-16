//
//  ClientSettingsViewController.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import UIKit

class ClientSettingsViewController: UIViewController {
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }
        let title: String
        let iconName: String
        switch indexPath.row {
        case 0:
            title = "Edit Profile"
            iconName = "person.fill"
        case 1:
            title = "Notifications"
            iconName = "bell.fill"
        case 2:
            title = "Help"
            iconName = "questionmark.circle.fill"
        case 3:
            title = "Logout"
            iconName = "arrow.right.square.fill"
        default:
            title = ""
            iconName = ""
        }
        cell.configure(with: title, iconName: iconName)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
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
            print("Logout tapped")
            handleLogout()
        default:
            break
        }
    }
    
    private func handleLogout() {
        AuthService.shared.logout()
        
        // Navigate back to sign in
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let welcomeVC = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController")
        let navigationController = UINavigationController(rootViewController: welcomeVC)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
        window?.windows.first?.rootViewController = navigationController
    }
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
            titleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // Subtitle Label
            subtitleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 21)
        ])
    }
    
    func configure(with title: String, iconName: String) {
        titleLabel.text = title
        subtitleLabel.isHidden = true
        
        profileImageView.isHidden = true
        iconContainer.isHidden = false
        iconContainer.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        iconImageView.image = UIImage(systemName: iconName)
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
