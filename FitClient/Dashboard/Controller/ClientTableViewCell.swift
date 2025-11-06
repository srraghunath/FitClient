//
//  ClientTableViewCell.swift
//  FitClient
//
//  Created by admin8 on 05/11/25.
//

import UIKit

class ClientTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .black
        selectionStyle = .none
        
        profileImageView.layer.cornerRadius = 28
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
    
    func configure(with client: Client) {
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
