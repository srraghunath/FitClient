//
//  SignUpClientViewController.swift
//  FitClient
//
//  Created by admin6 on 12/11/25.
//

import UIKit

class SignUpClientViewController: UIViewController {
    
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var goalTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var createAccountButton: UIButton!
    
    let genderPicker = UIPickerView()
    var genderOptions: [String] = []
    let goalPicker = UIPickerView()
    var goalOptions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSignupOptions()
        setupUI()
        setupGenderPicker()
        setupGoalPicker()
    }
    
    func loadSignupOptions() {
        DataService.shared.loadSignupOptions { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let options):
                    self?.genderOptions = options.genderOptions
                    self?.goalOptions = options.goalOptions
                    self?.genderPicker.reloadAllComponents()
                    self?.goalPicker.reloadAllComponents()
                case .failure(let error):
                    print("Failed to load signup options: \(error)")
                }
            }
        }
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        setupStandardNavigationBar(title: "Sign Up")
        
        fullNameTextField.applyAppStyle(placeholder: "Full Name")
        
        ageTextField.applyAppStyle(placeholder: "Age")
        ageTextField.keyboardType = .numberPad
        
        genderTextField.applyAppStyle(placeholder: "Gender")
        genderTextField.inputView = genderPicker
        
        goalTextField.applyAppStyle(placeholder: "Goal")
        goalTextField.inputView = goalPicker
        
        emailTextField.applyAppStyle(placeholder: "Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        
        passwordTextField.applyAppStyle(placeholder: "Password")
        passwordTextField.isSecureTextEntry = true
        
        createAccountButton.applyPrimaryStyle(title: "Create Account")
    }
    
    func setupGenderPicker() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        genderPicker.tag = 1
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGender))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flex, doneButton], animated: false)
        genderTextField.inputAccessoryView = toolbar
    }
    
    func setupGoalPicker() {
        goalPicker.delegate = self
        goalPicker.dataSource = self
        goalPicker.tag = 2
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGoal))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flex, doneButton], animated: false)
        goalTextField.inputAccessoryView = toolbar
    }
    
    @objc func donePickingGender() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = genderOptions[selectedRow]
        view.endEditing(true)
    }
    
    @objc func donePickingGoal() {
        let selectedRow = goalPicker.selectedRow(inComponent: 0)
        goalTextField.text = goalOptions[selectedRow]
        view.endEditing(true)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        guard let fullName = fullNameTextField.text, !fullName.isEmpty,
              let age = ageTextField.text, !age.isEmpty,
              let gender = genderTextField.text, !gender.isEmpty,
              let goal = goalTextField.text, !goal.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }
        
        if email.isValidEmail {
            navigateToDashboard()
        } else {
            showAlert(message: "Please enter a valid email address")
        }
    }
    
    private func navigateToDashboard() {
        let tabBarController = MainTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.modalTransitionStyle = .crossDissolve
        present(tabBarController, animated: true)
    }
}

extension SignUpClientViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return genderOptions.count
        } else {
            return goalOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return genderOptions[row]
        } else {
            return goalOptions[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            genderTextField.text = genderOptions[row]
        } else {
            goalTextField.text = goalOptions[row]
        }
    }
}
