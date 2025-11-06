import UIKit

class ForgotPassword: UIViewController {

    @IBOutlet weak var forgotPasswordTextfeild: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Forgot Password"
        navigationController?.navigationBar.tintColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        
        forgotPasswordTextfeild.applyStyle("Email")
        forgotPasswordTextfeild.autocapitalizationType = .none
        forgotPasswordTextfeild.keyboardType = .emailAddress
        forgotPasswordTextfeild.autocorrectionType = .no
    }

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

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
