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
        forgotPasswordTextfeild.placeholder = "Email"
        forgotPasswordTextfeild.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        forgotPasswordTextfeild.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        forgotPasswordTextfeild.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        forgotPasswordTextfeild.layer.cornerRadius = 12
        forgotPasswordTextfeild.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        forgotPasswordTextfeild.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        forgotPasswordTextfeild.leftViewMode = .always
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
