//
//  CardioInputCell.swift
//  FitClient
//
//  Created by admin6 on 11/11/25.
//

import UIKit

protocol CardioInputCellDelegate: AnyObject {
    func cardioInputCell(_ cell: CardioInputCell, didUpdateValue text: String)
}

class CardioInputCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textField: UITextField!
    
    // MARK: - Properties
    weak var delegate: CardioInputCellDelegate?
    private var cardioText: String = ""
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Card styling
        cardView.backgroundColor = UIColor(hex: "#303131")
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = true
        
        // Title styling
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .white
        
        // TextField styling
        textField.delegate = self
        textField.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter cardio plan (e.g. 20 mins Running)",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        textField.font = UIFont.systemFont(ofSize: 12)
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    // MARK: - Configure
    func configure(with cardioValue: String = "") {
        self.cardioText = cardioValue
        titleLabel.text = "Cardio"
        textField.text = cardioValue
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        cardioText = textField.text ?? ""
        delegate?.cardioInputCell(self, didUpdateValue: cardioText)
    }
}

// MARK: - UITextFieldDelegate
extension CardioInputCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
