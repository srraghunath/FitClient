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
    private var loader: ActivityLoader?
    
    let genderPicker = UIPickerView()
    var genderOptions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSignupOptions()
        setupUI()
        setupGenderPicker()
    }
    
    func loadSignupOptions() {
        DataService.shared.loadSignupOptions { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let options):
                    self?.genderOptions = options.genderOptions
                    self?.genderPicker.reloadAllComponents()
                case .failure(let error):
                    print("Failed to load signup options: \(error)")
                }
            }
        }
    }
    
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
              let age = ageTextField.text, !age.isEmpty,
              let gender = genderTextField.text, !gender.isEmpty,
              let specialization = specializationTextField.text, !specialization.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill all fields")
            return
        }

        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match")
            return
        }

        loader = ActivityLoader.show(over: view)

        AuthService.shared.signUp(email: email, password: password, fullName: fullName, age: age, gender: gender, specialization: specialization) { [weak self] error in
            DispatchQueue.main.async {
                self?.loader?.hide()
                if let error = error {
                    self?.showAlert(message: "Error signing up: \(error.localizedDescription)")
                } else {
                    self?.showAlert(message: "Sign up successful! Please check your email to verify your account.") {
                        self?.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
        }
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
