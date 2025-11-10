

import UIKit

class AddClientModalViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    var onClientAdded: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextField()
        setupButton()
        setupKeyboardDismissal()
    }
    
    private func setupTextField() {
        emailTextField.applyAppStyle(placeholder: "Enter email address")
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.returnKeyType = .done
        emailTextField.delegate = self
    }
    
    private func setupButton() {
        addButton.applyPrimaryStyle(title: "Add Client")
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAlert(message: "Please enter an email address")
            return
        }
        
        guard email.isValidEmail else {
            showAlert(message: "Please enter a valid email address")
            return
        }
        
        onClientAdded?(email)
        dismiss(animated: true)
    }
}

extension AddClientModalViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
