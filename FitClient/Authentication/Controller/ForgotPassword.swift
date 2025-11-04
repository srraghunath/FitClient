//
//  ForgotPassword.swift
//  FitClient
//
//  Created by admin6 on 04/11/25.
//

import UIKit

class ForgotPassword: UIViewController {

    @IBOutlet weak var forgotPasswordTextfeild: UITextField!

    
    @IBOutlet weak var Backbutton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // Email text field
        setTextField(forgotPasswordTextfeild, "Email")
        forgotPasswordTextfeild.autocapitalizationType = .none
        forgotPasswordTextfeild.keyboardType = .emailAddress
        forgotPasswordTextfeild.autocorrectionType = .no
    }

    // Reset Password Button
    @IBAction func resetPasswordPressed(_ sender: Any) {
        guard let email = forgotPasswordTextfeild.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAlert(message: "Please enter your email.")
            return
        }

        if isValidEmail(email) {
            print("Entered Email: \(email)")
            showAlert(message: "Verification Link Sent")
        } else {
            showAlert(message: "Please enter a valid email address.")
        }
    }

    // Email validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    // Reusable Alert
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
