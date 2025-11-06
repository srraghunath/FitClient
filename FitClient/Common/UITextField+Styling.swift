//
//  UITextField+Styling.swift
//  FitClient
//
//  Created on 06/11/25.
//

import UIKit

extension UITextField {
    func applyAppStyle(placeholder: String) {
        self.placeholder = placeholder
        self.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        self.textColor = .textPrimary
        self.backgroundColor = .backgroundGray
        self.layer.cornerRadius = 12
        self.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.textSecondary]
        )
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        self.leftViewMode = .always
    }
}
