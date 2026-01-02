//
//  ForgotPasswordClientViewController.swift
//  FitClient
//
//  Created by admin6 on 12/11/25.
//

import UIKit

class ForgotPasswordClientViewController: UIViewController {

    @IBOutlet weak var forgotPasswordTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        setupStandardNavigationBar(title: "Forgot Password")
        
        // Email text field
        forgotPasswordTextfield.applyAppStyle(placeholder: "Email")
        forgotPasswordTextfield.autocapitalizationType = .none
        forgotPasswordTextfield.keyboardType = .emailAddress
        forgotPasswordTextfield.autocorrectionType = .no
    }

    @IBAction func resetPasswordPressed(_ sender: Any) {
        guard let email = forgotPasswordTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAlert(message: "Please enter your email.")
            return
        }

        if email.isValidEmail {
            AuthService.shared.forgotPassword(email: email) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(message: "Error sending reset link: \(error.localizedDescription)")
                    } else {
                        self?.showAlert(message: "A password reset link has been sent to your email.") {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        } else {
            showAlert(message: "Please enter a valid email address.")
        }
    }
}
