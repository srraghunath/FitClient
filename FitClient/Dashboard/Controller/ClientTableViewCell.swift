

import UIKit

protocol ClientTableViewCellDelegate: AnyObject {
    func didTapChatButton(for client: Client)
}

class ClientTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    weak var delegate: ClientTableViewCellDelegate?
    private var client: Client?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupChatButton()
    }
    
    private func setupUI() {
        backgroundColor = .black
        selectionStyle = .none
        
        profileImageView.layer.cornerRadius = 28
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
    
    private func setupChatButton() {
        chevronImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chatButtonTapped))
        chevronImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func chatButtonTapped() {
        if let client = client {
            delegate?.didTapChatButton(for: client)
        }
    }
    
    func configure(with client: Client) {
        self.client = client
        nameLabel.text = client.name
        levelLabel.text = client.level
        
        if let url = URL(string: client.profileImage) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async { self.profileImageView.image = image }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .primaryGreen
        }
    }
}
