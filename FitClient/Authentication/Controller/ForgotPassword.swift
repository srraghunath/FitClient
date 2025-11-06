import UIKit

class ForgotPassword: UIViewController {

    @IBOutlet weak var forgotPasswordTextfeild: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        setupStandardNavigationBar(title: "Forgot Password")
        
        // Email text field
        forgotPasswordTextfeild.applyAppStyle(placeholder: "Email")
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

        if email.isValidEmail {
            print("Entered Email: \(email)")
            showAlert(message: "Verification Link Sent")
        } else {
            showAlert(message: "Please enter a valid email address.")
        }
    }
}
