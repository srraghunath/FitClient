//
//  SessionTableViewCell.swift
//  FitClient
//
//  Created by admin8 on 04/11/25.
//

import UIKit

class SessionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var clientNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Set corner radius in layoutSubviews to ensure frame is set
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    }
    
    private func setupUI() {
        // Container styling
        containerView.backgroundColor = UIColor(hex: "#303131")
        containerView.layer.cornerRadius = 36
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6.857)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 27.429
        
        // Profile image styling
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = UIColor(hex: "#D7CCC8")
        
        // Client name label styling
        clientNameLabel.font = UIFont(name: "Arimo-Bold", size: 15.429) ?? UIFont.boldSystemFont(ofSize: 15.429)
        clientNameLabel.textColor = .white
        
        // Time label styling
        timeLabel.font = UIFont(name: "Arimo-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        
        // Chevron icon styling
        chevronImageView.tintColor = UIColor.white

        
        // Background
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(with session: Session) {
        clientNameLabel.text = session.clientName
        timeLabel.text = "\(session.startTime) - \(session.endTime)"
        
        // Load profile image from assets
        if let image = UIImage(named: session.clientProfileImage) {
            profileImageView.image = image
        } else {
            // Fallback to SF Symbol
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = UIColor(hex: "#D7CCC8")
        }
        
        // Set chevron icon using SF Symbol
        chevronImageView.image = UIImage(systemName: "chevron.right")
    }
}

// Helper extension for hex colors
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
