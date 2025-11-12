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
            print("Entered Email: \(email)")
            showAlert(message: "Verification Link Sent")
        } else {
            showAlert(message: "Please enter a valid email address.")
        }
    }
}
