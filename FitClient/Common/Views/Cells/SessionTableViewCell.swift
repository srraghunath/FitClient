
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
        containerView.layer.cornerRadius = 36
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6.857)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 27.429
        
        // Profile image styling
        profileImageView.clipsToBounds = true
        
        // Client name label styling
        clientNameLabel.font = UIFont(name: "Lexend-Regular", size: 15.429) ?? UIFont.boldSystemFont(ofSize: 15.429)
        clientNameLabel.textColor = .white
        
        // Time label styling
        timeLabel.font = UIFont(name: "Lexend-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
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
        
        if let url = URL(string: session.clientProfileImage) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async { self.profileImageView.image = image }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = UIColor(hex: "#D7CCC8")
        }
        
        // Set chevron icon using SF Symbol
        chevronImageView.image = UIImage(systemName: "chevron.right")
    }
}
