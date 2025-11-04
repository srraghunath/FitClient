//
//  UI.swift
//  FitClient
//
//  Created by admin8 on 04/11/25.
//

import UIKit

func setTextField(_ textField: UITextField, _ placeholder: String) {
    textField.placeholder = placeholder
    textField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
    textField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
    textField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
    textField.layer.cornerRadius = 12
    textField.attributedPlaceholder = NSAttributedString(
        string: placeholder,
        attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
    )
    textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
    textField.leftViewMode = .always
}

