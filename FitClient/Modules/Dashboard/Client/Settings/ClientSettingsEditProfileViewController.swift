
import UIKit

class ClientSettingsEditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField! // Used as Age field
    @IBOutlet weak var goalTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!

    // MARK: - Properties
    private var profile: ClientProfileRecord?
    private let genderPicker = UIPickerView()
    private let goalPicker = UIPickerView()
    private var genderOptions: [String] = []
    private var goalOptions: [String] = []
    private var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupPickers()
        loadClientProfile()
        hideKeyboardWhenTappedAround()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Setup Methods

    private func setupNavigationBar() {
        title = "Edit Profile"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.sizeToFit()
        backButton.tintColor = .primaryGreen
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }

    private func setupUI() {
        view.backgroundColor = .black

        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.primaryGreen.cgColor
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = UIColor(hex: "#212121")

        setupTextField(nameTextField)
        setupTextField(emailTextField)
        setupTextField(phoneTextField)
        setupTextField(goalTextField)
        setupTextField(genderTextField)

        phoneTextField.keyboardType = .numberPad
        emailTextField.isUserInteractionEnabled = false
    }

    private func setupTextField(_ textField: UITextField) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.rightViewMode = .always
    }

    private func setupPickers() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        genderPicker.tag = 1
        goalPicker.delegate = self
        goalPicker.dataSource = self
        goalPicker.tag = 2

        genderTextField.inputView = genderPicker
        goalTextField.inputView = goalPicker

        let genderToolbar = UIToolbar()
        genderToolbar.sizeToFit()
        genderToolbar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGender))
        ], animated: false)
        genderTextField.inputAccessoryView = genderToolbar

        let goalToolbar = UIToolbar()
        goalToolbar.sizeToFit()
        goalToolbar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGoal))
        ], animated: false)
        goalTextField.inputAccessoryView = goalToolbar
    }

    // MARK: - Data Loading

    private func loadClientProfile() {
        loadSignupOptions()

        ClientProfileService.shared.fetchProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self?.profile = profile
                    self?.updateUI(with: profile)
                case .failure(let error):
                    print("[ClientSettingsEditProfile] Failed to load profile: \(error)")
                    self?.showAlert(title: "Error", message: "Failed to load profile: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadSignupOptions() {
        DataService.shared.loadSignupOptions { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let options):
                    self?.genderOptions = options.genderOptions
                    self?.goalOptions = options.goalOptions
                    self?.genderPicker.reloadAllComponents()
                    self?.goalPicker.reloadAllComponents()
                case .failure(let error):
                    print("[ClientSettingsEditProfile] Failed to load signup options: \(error)")
                }
            }
        }
    }

    private func updateUI(with profile: ClientProfileRecord) {
        nameTextField.text = profile.fullName
        emailTextField.text = AuthService.shared.supabase.auth.currentUser?.email
        if let age = profile.age { phoneTextField.text = String(age) }
        genderTextField.text = profile.gender
        goalTextField.text = profile.goal

        if let urlString = profile.profileImageURL, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }.resume()
        }
    }

    // MARK: - IBActions

    @IBAction func changePhotoTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            profileImageView.image = image
            selectedImage = image
        }
        dismiss(animated: true)
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let fullName = nameTextField.text, !fullName.isEmpty,
              let ageString = phoneTextField.text, !ageString.isEmpty,
              let age = Int(ageString), age > 0,
              let gender = genderTextField.text, !gender.isEmpty,
              let goal = goalTextField.text, !goal.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        guard let userId = AuthService.shared.supabase.auth.currentUser?.id else {
            showAlert(title: "Error", message: "Please log in again")
            return
        }

        func performSave(with imageURL: String?) {
            let finalUpdate = ClientProfileUpdatePayload(
                full_name: fullName,
                age: age,
                gender: gender,
                goal: goal,
                profile_image_url: imageURL
            )

            ClientProfileService.shared.updateProfile(finalUpdate) { [weak self] error in
                DispatchQueue.main.async {
                    if let error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        self?.showAlert(title: "Success", message: "Profile updated") { [weak self] in
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }

        if let image = selectedImage {
            ClientProfileService.shared.uploadProfileImage(image, for: userId) { [weak self] result in
                switch result {
                case .success(let url):
                    performSave(with: url)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        } else {
            performSave(with: profile?.profileImageURL)
        }
    }

    // MARK: - Keyboard Handling

    private func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Picker Delegates

extension ClientSettingsEditProfileViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.tag == 1 ? genderOptions.count : goalOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerView.tag == 1 ? genderOptions[row] : goalOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            genderTextField.text = genderOptions[row]
        } else {
            goalTextField.text = goalOptions[row]
        }
    }

    @objc private func donePickingGender() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        guard genderOptions.indices.contains(selectedRow) else { return }
        genderTextField.text = genderOptions[selectedRow]
        view.endEditing(true)
    }

    @objc private func donePickingGoal() {
        let selectedRow = goalPicker.selectedRow(inComponent: 0)
        guard goalOptions.indices.contains(selectedRow) else { return }
        goalTextField.text = goalOptions[selectedRow]
        view.endEditing(true)
    }
}
