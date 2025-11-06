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
        view.backgroundColor = .black
        
        navigationController?.navigationBar.tintColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        
        fullNameTextField.applyStyle("Full Name")
        
        ageTextField.applyStyle("Age")
        ageTextField.keyboardType = .numberPad
        
        genderTextField.applyStyle("Gender")
        genderTextField.inputView = genderPicker
        
        specializationTextField.applyStyle("Specialization")
        
        emailTextField.applyStyle("Email")
        emailTextField.autocapitalizationType = .none
        emailTextField.keyboardType = .emailAddress
        
        passwordTextField.applyStyle("Password")
        passwordTextField.isSecureTextEntry = true
        
        confirmPasswordTextField.applyStyle("Confirm Password")
        confirmPasswordTextField.isSecureTextEntry = true
        
        createAccountButton.setTitle("Create Account", for: .normal)
        createAccountButton.setTitleColor(.black, for: .normal)
        createAccountButton.backgroundColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0)
        createAccountButton.titleLabel?.font = UIFont(name: "Lexend-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        createAccountButton.layer.cornerRadius = 24
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
        print("Create Account tapped")
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
