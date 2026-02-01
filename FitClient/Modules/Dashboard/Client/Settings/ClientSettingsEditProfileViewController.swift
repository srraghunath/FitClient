import UIKit

class ClientSettingsEditProfileViewController: UIViewController,
                                               UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate,
                                               UIPickerViewDelegate,
                                               UIPickerViewDataSource {

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
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
        view.backgroundColor = .backgroundBlack

        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.primaryGreen.cgColor
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = UIColor(hex: "#212121")

        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        )

        configureTextFields()
        phoneTextField.keyboardType = .numberPad
        emailTextField.isUserInteractionEnabled = false
        saveButton.applyPrimaryStyle(title: "Save Changes")
    }

    private func configureTextFields() {
        let fields: [(UITextField, String)] = [
            (nameTextField, "Full Name"),
            (emailTextField, "Email"),
            (phoneTextField, "Age"),
            (genderTextField, "Gender"),
            (goalTextField, "Goal")
        ]

        fields.forEach { field, placeholder in
            field.borderStyle = .none
            field.applyAppStyle(placeholder: placeholder)
            field.keyboardAppearance = .dark
        }
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
                    self?.alignGenderPickerWithCurrentSelection()
                    self?.alignGoalPickerWithCurrentSelection()
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

        alignGenderPickerWithCurrentSelection()
        alignGoalPickerWithCurrentSelection()

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
        profileImageTapped()
    }

    @objc private func profileImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true

        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                picker.sourceType = .camera
                self.present(picker, animated: true)
            })
        }

        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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

extension ClientSettingsEditProfileViewController {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.tag == 1 ? genderOptions.count : goalOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerView.tag == 1 ? genderOptions[row] : goalOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            guard genderOptions.indices.contains(row) else { return }
            genderTextField.text = genderOptions[row]
        } else {
            guard goalOptions.indices.contains(row) else { return }
            goalTextField.text = goalOptions[row]
        }
    }

    @objc private func donePickingGender() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        guard genderOptions.indices.contains(selectedRow) else {
            view.endEditing(true)
            return
        }
        genderTextField.text = genderOptions[selectedRow]
        view.endEditing(true)
    }

    @objc private func donePickingGoal() {
        let selectedRow = goalPicker.selectedRow(inComponent: 0)
        guard goalOptions.indices.contains(selectedRow) else {
            view.endEditing(true)
            return
        }
        goalTextField.text = goalOptions[selectedRow]
        view.endEditing(true)
    }

    private func alignGenderPickerWithCurrentSelection() {
        guard !genderOptions.isEmpty else { return }
        let current = genderTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let current,
           let index = genderOptions.firstIndex(where: { $0.caseInsensitiveCompare(current) == .orderedSame }) {
            genderPicker.selectRow(index, inComponent: 0, animated: false)
            genderTextField.text = genderOptions[index]
        } else {
            genderPicker.selectRow(0, inComponent: 0, animated: false)
            if (current ?? "").isEmpty {
                genderTextField.text = genderOptions.first
            }
        }
    }

    private func alignGoalPickerWithCurrentSelection() {
        guard !goalOptions.isEmpty else { return }
        let current = goalTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let current,
           let index = goalOptions.firstIndex(where: { $0.caseInsensitiveCompare(current) == .orderedSame }) {
            goalPicker.selectRow(index, inComponent: 0, animated: false)
            goalTextField.text = goalOptions[index]
        } else {
            goalPicker.selectRow(0, inComponent: 0, animated: false)
            if (current ?? "").isEmpty {
                goalTextField.text = goalOptions.first
            }
        }
    }
}
