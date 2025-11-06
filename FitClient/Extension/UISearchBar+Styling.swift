//
//  UISearchBar+Styling.swift
//  FitClient
//
//  Created on 06/11/25.
//

import UIKit

extension UISearchBar {
    func applyAppStyle() {
        self.searchBarStyle = .minimal
        self.barTintColor = .black
        self.backgroundColor = .black
        self.backgroundImage = UIImage()
        
        self.searchTextField.backgroundColor = .backgroundGray
        self.searchTextField.textColor = .textPrimary
        self.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [.foregroundColor: UIColor.textPrimary.withAlphaComponent(0.6)]
        )
        self.searchTextField.leftView?.tintColor = .textPrimary
    }
}
