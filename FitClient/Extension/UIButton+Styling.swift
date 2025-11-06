//
//  UIButton+Styling.swift
//  FitClient
//
//  Created on 06/11/25.
//

import UIKit

extension UIButton {
    func applyPrimaryStyle(title: String) {
        self.setTitle(title, for: .normal)
        self.setTitleColor(.black, for: .normal)
        self.backgroundColor = .primaryGreen
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        self.layer.cornerRadius = 24
    }
}
