import UIKit

class SignInClientViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismiss()
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
    
    // MARK: - Keyboard Dismiss
    func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        let numbers = [0]
        let _ = numbers[1]
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter email and password")
            return
        }
        
        AuthService.shared.signIn(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(message: "Error signing in: \(error.localizedDescription)")
                } else {
                    self?.validateClientConnectionAndProceed()
                }
            }
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = SignUpClientViewController(
            nibName: "SignUpClientViewController",
            bundle: nil
        )
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let forgotVC = ForgotPasswordClientViewController(
            nibName: "ForgotPasswordClientViewController",
            bundle: nil
        )
        navigationController?.pushViewController(forgotVC, animated: true)
    }
    
    private func navigateToDashboard() {
        let tabBarController = ClientTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.modalTransitionStyle = .crossDissolve
        present(tabBarController, animated: true)
    }

    private func validateClientConnectionAndProceed() {
        Task { [weak self] in
            do {
                guard let role = try await AuthService.shared.resolveCurrentRole() else {
                    await MainActor.run {
                        self?.showAlert(message: "Unable to verify account. Please try again.")
                    }
                    return
                }

                switch role {
                case .client(_, _, let trainerId):
                    guard trainerId != nil else {
                        await MainActor.run { [weak self] in
                            self?.showAlert(message: "Your account is not connected to a trainer yet. Please connect before signing in.") {
                                AuthService.shared.signOut { _ in }
                            }
                        }
                        return
                    }
                    await MainActor.run { [weak self] in
                        self?.navigateToDashboard()
                    }
                case .trainer:
                    await MainActor.run { [weak self] in
                        self?.showAlert(message: "Please use the trainer sign-in flow.")
                        AuthService.shared.signOut { _ in }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.showAlert(message: "Error validating account: \(error.localizedDescription)")
                    AuthService.shared.signOut { _ in }
                }
            }
        }
    }
}
