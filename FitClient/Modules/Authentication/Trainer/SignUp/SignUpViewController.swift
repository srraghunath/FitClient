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
    var genderOptions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        loadSignupOptions()
        genderOptions = ["Male", "Female", "Other"]
        setupUI()
        setupGenderPicker()
    }
    
//    func loadSignupOptions() {
//        DataService.shared.loadSignupOptions { [weak self] result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let options):
//                    self?.genderOptions = options.genderOptions
//                    self?.genderPicker.reloadAllComponents()
//                case .failure(let error):
//                    print("Failed to load signup options: \(error)")
//                }
//            }
//        }
//    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        setupStandardNavigationBar()
        
        fullNameTextField.applyAppStyle(placeholder: "Full Name")
        
        ageTextField.applyAppStyle(placeholder: "Age")
        ageTextField.keyboardType = .numberPad
        
        genderTextField.applyAppStyle(placeholder: "Gender")
        genderTextField.inputView = genderPicker
        
        specializationTextField.applyAppStyle(placeholder: "Specialization")
        
        emailTextField.applyAppStyle(placeholder: "Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        
        passwordTextField.applyAppStyle(placeholder: "Password")
        passwordTextField.isSecureTextEntry = true
        
        confirmPasswordTextField.applyAppStyle(placeholder: "Confirm Password")
        confirmPasswordTextField.isSecureTextEntry = true
        
        createAccountButton.applyPrimaryStyle(title: "Create Account")
    }
    
    func setupGenderPicker() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGender))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flex, doneButton], animated: false)
        genderTextField.inputAccessoryView = toolbar
    }
    
    @objc func donePickingGender() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = genderOptions[selectedRow]
        view.endEditing(true)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        guard let fullName = fullNameTextField.text, !fullName.isEmpty,
              let ageString = ageTextField.text, let age = Int(ageString),
              let gender = genderTextField.text, !gender.isEmpty,
              let specialization = specializationTextField.text, !specialization.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }

        if password != confirmPassword {
            showAlert(message: "Passwords do not match")
            return
        }
        
        if !email.isValidEmail {
            showAlert(message: "Please enter a valid email address")
            return
        }

        AuthService.shared.signup(email: email, password: password, fullName: fullName, role: "TRAINER", specialization: specialization) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showAlert(message: "Signup successful! Please log in.", completion: {
                        self?.navigationController?.popViewController(animated: true)
                    })
                } else {
                    self?.showAlert(message: "Signup failed. Please check the details and try again.")
                }
            }
        }
    }

    private func navigateToDashboard() {
        let tabBarController = MainTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.modalTransitionStyle = .crossDissolve
        present(tabBarController, animated: true)
    }
}

extension SignUpViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { genderOptions.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { genderOptions[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderTextField.text = genderOptions[row]
    }
}
