//
//  UIViewController+Alert.swift
//  FitClient
//
//  Created on 06/11/25.
//

import UIKit

extension UIViewController {
    func showAlert(title: String = "Alert", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
