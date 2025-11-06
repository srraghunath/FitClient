//
//  UIViewController+Navigation.swift
//  FitClient
//
//  Created on 06/11/25.
//

import UIKit

extension UIViewController {
    func setupStandardNavigationBar(title: String? = nil) {
        navigationController?.navigationBar.tintColor = .primaryGreen
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.backgroundColor = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        if let title = title {
            self.title = title
        }
    }
}
