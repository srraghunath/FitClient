//
//  SignUpViewController.swift
//  FitClient
//
//  Created by admin6 on 03/11/25.
//

import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var specializationTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var createAccountButton: UIButton!
    
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
        setTextField(fullNameTextField, "Full Name")
        
        // Age text field
        setTextField(ageTextField, "Age")
        ageTextField.keyboardType = .numberPad
        
        // Gender text field (with picker)
        setTextField(genderTextField, "Gender")
        genderTextField.inputView = genderPicker
        
        // Specialization text field
        setTextField(specializationTextField, "Specialization")
        
        // Email text field
        setTextField(emailTextField, "Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        
        setTextField(passwordTextField, "Password")
        passwordTextField.isSecureTextEntry = true
        
        // Confirm Password text field
        setTextField(confirmPasswordTextField, "Confirm Password")
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
