//
//  SignInClientViewController.swift
//  FitClient
//
//  Created by admin6 on 12/11/25.
//

import UIKit

class SignInClientViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        // Background color
        view.backgroundColor = .black
        
        // Email text field
        emailTextField.applyAppStyle(placeholder: "Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress

        
        // Password text field
        passwordTextField.applyAppStyle(placeholder: "Password")
        passwordTextField.isSecureTextEntry = true
        
        // Sign In button
        signInButton.applyPrimaryStyle(title: "Sign In")
    }
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter email and password")
            return
        }
        
        navigateToDashboard()
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = SignUpClientViewController(nibName: "SignUpClientViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let forgotVC = ForgotPasswordClientViewController(nibName: "ForgotPasswordClientViewController", bundle: nil)
        navigationController?.pushViewController(forgotVC, animated: true)
    }
    
    private func navigateToDashboard() {
        let tabBarController = MainTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.modalTransitionStyle = .crossDissolve
        present(tabBarController, animated: true)
    }
}
