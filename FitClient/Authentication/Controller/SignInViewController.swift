//
//  SignInViewController.swift
//  FitClient
//
//  Created by admin8 on 03/11/25.
//

import UIKit

class SignInViewController: UIViewController {
    
    // IBOutlets
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
        setTextField(emailTextField, "Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress

        
        // Password text field
        setTextField(passwordTextField, "Password")
        passwordTextField.isSecureTextEntry = true
        
        // Sign In button
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(.black, for: .normal)
        signInButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        signInButton.layer.cornerRadius = 24
    }
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        // Basic validation
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter email and password")
            return
        }
        
        // TODO: Add proper authentication logic here
        // For now, navigate to dashboard
        navigateToDashboard()
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        print("signup tapped")
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        signUpVC.modalPresentationStyle = .fullScreen
        signUpVC.modalTransitionStyle = .crossDissolve
        present(signUpVC, animated: true, completion: nil)
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        print("Forgot Password tapped")
        let forgotVC = ForgotPassword(nibName: "ForgotPassword", bundle: nil)
        forgotVC.modalPresentationStyle = .fullScreen
        forgotVC.modalTransitionStyle = .crossDissolve
        present(forgotVC, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Sign In", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToDashboard() {
        let tabBarController = MainTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.modalTransitionStyle = .crossDissolve
        present(tabBarController, animated: true, completion: nil)
    }

}
