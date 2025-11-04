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
        emailTextField.placeholder = "Email"
        emailTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        emailTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        emailTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        emailTextField.layer.cornerRadius = 12
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        emailTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        emailTextField.leftViewMode = .always
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress

        
        // Password text field
        passwordTextField.placeholder = "Password"
        passwordTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        passwordTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        passwordTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        passwordTextField.layer.cornerRadius = 12
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        passwordTextField.leftViewMode = .always
        passwordTextField.isSecureTextEntry = true
        
        // Sign In button
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(.black, for: .normal)
        signInButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        signInButton.layer.cornerRadius = 24
    }
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        // Implement sign in logic
        print("Sign In tapped")
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
}
