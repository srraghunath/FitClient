import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        emailTextField.applyStyle("Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        
        passwordTextField.applyStyle("Password")
        passwordTextField.isSecureTextEntry = true
        
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.setTitleColor(.black, for: .normal)
        signInButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        signInButton.layer.cornerRadius = 24
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
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let forgotVC = ForgotPassword(nibName: "ForgotPassword", bundle: nil)
        navigationController?.pushViewController(forgotVC, animated: true)
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
        present(tabBarController, animated: true)
    }
}
