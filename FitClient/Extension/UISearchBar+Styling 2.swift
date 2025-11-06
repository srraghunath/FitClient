//
//  UISearchBar+Styling.swift
//  FitClient
//
//  Created on 06/11/25.
//

import UIKit

extension UISearchBar {
    func applyAppStyle() {
        // Force dark appearance to prevent color changes
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .dark
        }
        
        self.searchBarStyle = .minimal
        self.barTintColor = .black
        self.backgroundColor = .black
        self.backgroundImage = UIImage()
        self.tintColor = .primaryGreen
        
        // Set text field colors
        self.searchTextField.backgroundColor = .backgroundGray
        self.searchTextField.textColor = .textPrimary
        self.searchTextField.tintColor = .primaryGreen
        
        // Set placeholder
        self.searchTextField.attributedPlaceholder = NSAttributedString(
            string: self.placeholder ?? "Search",
            attributes: [.foregroundColor: UIColor.textPrimary.withAlphaComponent(0.6)]
        )
        
        // Set search icon color
        if let leftView = self.searchTextField.leftView as? UIImageView {
            leftView.tintColor = .textPrimary.withAlphaComponent(0.6)
            leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
        }
        
        // Set clear button color - always visible with proper styling
        if let clearButton = self.searchTextField.value(forKey: "_clearButton") as? UIButton {
            clearButton.setImage(clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            clearButton.tintColor = .textPrimary.withAlphaComponent(0.6)
        }
    }
}
