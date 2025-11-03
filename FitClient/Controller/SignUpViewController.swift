//
//  SignUpViewController.swift
//  FitClient
//
//  Created by admin6 on 03/11/25.
//

import UIKit

class SignUpViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var specializationTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var createAccountButton: UIButton!
    
    // Gender picker
    let genderPicker = UIPickerView()
    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGenderPicker()
    }
    
    func setupUI() {
        // Background color
        view.backgroundColor = .black
        
        // Full Name text field
        fullNameTextField.placeholder = "Full Name"
        fullNameTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        fullNameTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        fullNameTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        fullNameTextField.layer.cornerRadius = 12
        fullNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Full Name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        fullNameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        fullNameTextField.leftViewMode = .always
        
        // Age text field
        ageTextField.placeholder = "Age"
        ageTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        ageTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        ageTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        ageTextField.layer.cornerRadius = 12
        ageTextField.attributedPlaceholder = NSAttributedString(
            string: "Age",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        ageTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        ageTextField.leftViewMode = .always
        ageTextField.keyboardType = .numberPad
        
        // Gender text field (with picker)
        genderTextField.placeholder = "Gender"
        genderTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        genderTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        genderTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        genderTextField.layer.cornerRadius = 12
        genderTextField.attributedPlaceholder = NSAttributedString(
            string: "Gender",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        genderTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        genderTextField.leftViewMode = .always
        
        // Specialization text field
        specializationTextField.placeholder = "Specialisation"
        specializationTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        specializationTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        specializationTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        specializationTextField.layer.cornerRadius = 12
        specializationTextField.attributedPlaceholder = NSAttributedString(
            string: "Specialisation",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        specializationTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        specializationTextField.leftViewMode = .always
        
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
        
        // Confirm Password text field
        confirmPasswordTextField.placeholder = "Confirm Password"
        confirmPasswordTextField.font = UIFont(name: "Lexend-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        confirmPasswordTextField.textColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        confirmPasswordTextField.backgroundColor = UIColor(red: 48/255, green: 49/255, blue: 49/255, alpha: 1.0)
        confirmPasswordTextField.layer.cornerRadius = 12
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(
            string: "Confirm Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 215/255, green: 204/255, blue: 200/255, alpha: 1.0)]
        )
        confirmPasswordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
        confirmPasswordTextField.leftViewMode = .always
        confirmPasswordTextField.isSecureTextEntry = true
        
        // Create Account button
        createAccountButton.setTitle("Create Account", for: .normal)
        createAccountButton.setTitleColor(.black, for: .normal)
        createAccountButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        createAccountButton.titleLabel?.font = UIFont(name: "Lexend-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        createAccountButton.layer.cornerRadius = 24
    }
    
    func setupGenderPicker() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        genderTextField.inputView = genderPicker
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGender))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        genderTextField.inputAccessoryView = toolbar
    }
    
    @objc func donePickingGender() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = genderOptions[selectedRow]
        view.endEditing(true)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        // Implement sign up logic
        print("Create Account tapped")
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension SignUpViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genderOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genderOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderTextField.text = genderOptions[row]
    }
}
