//
//  AddClientModalViewController.swift
//  FitClient
//
//  Created by admin8 on 06/11/25.
//

import UIKit

class AddClientModalViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    var onClientAdded: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTextField()
        setupButton()
        setupKeyboardDismissal()
    }
    
    private func setupNavigationBar() {
        title = "Add Client"
        
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: nil,
            action: nil
        )
        cancelButton.tintColor = .textPrimary
        cancelButton.primaryAction = UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }
        navigationItem.leftBarButtonItem = cancelButton
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
