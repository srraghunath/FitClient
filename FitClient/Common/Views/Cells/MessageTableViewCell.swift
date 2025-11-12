

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        messageContainerView.layer.cornerRadius = 16
    }
    
    func configure(with message: Message) {
        messageLabel.text = message.text
        timestampLabel.text = message.timestamp
        
        if message.isFromTrainer {
            // Trainer message (right side, green)
            messageContainerView.backgroundColor = .primaryGreen
            messageLabel.textColor = .black
            timestampLabel.textColor = .black.withAlphaComponent(0.6)
            trailingConstraint.constant = 16
            leadingConstraint.constant = 80
        } else {
            // Client message (left side, dark gray)
            messageContainerView.backgroundColor = UIColor(hex: "#212121")
            messageLabel.textColor = .white
            timestampLabel.textColor = .white.withAlphaComponent(0.6)
            trailingConstraint.constant = 80
            leadingConstraint.constant = 16
        }
    }
}
