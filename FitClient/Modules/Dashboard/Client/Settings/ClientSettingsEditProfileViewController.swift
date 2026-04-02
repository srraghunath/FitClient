import UIKit
import AVFoundation
import Photos

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
    private var genderOptions: [String] = []
    private var selectedImage: UIImage?
    private var loader: ActivityLoader?

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
            (goalTextField, "Profile Summary")
        ]

        fields.forEach { field, placeholder in
            field.borderStyle = .none
            field.applyAppStyle(placeholder: placeholder)
            field.keyboardAppearance = .dark
        }

        // Goal is no longer editable; this field now displays derived profile summary.
        goalTextField.isUserInteractionEnabled = false
    }

    private func setupPickers() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        genderPicker.tag = 1

        genderTextField.inputView = genderPicker

        let genderToolbar = UIToolbar()
        genderToolbar.sizeToFit()
        genderToolbar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePickingGender))
        ], animated: false)
        genderTextField.inputAccessoryView = genderToolbar

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
                    self?.genderPicker.reloadAllComponents()
                    self?.alignGenderPickerWithCurrentSelection()
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
        goalTextField.text = makeProfileSummary(age: profile.age, gender: profile.gender)

        alignGenderPickerWithCurrentSelection()

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
                self.checkCameraPermission { allowed in
                    if allowed {
                        picker.sourceType = .camera
                        self.present(picker, animated: true)
                    }
                }
            })
        }

        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.checkPhotoLibraryPermission { allowed in
                if allowed {
                    picker.sourceType = .photoLibrary
                    self.present(picker, animated: true)
                }
            }
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
              let gender = genderTextField.text, !gender.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        guard let userId = AuthService.shared.supabase.auth.currentUser?.id else {
            showAlert(title: "Error", message: "Please log in again")
            return
        }

        loader = ActivityLoader.show(over: view)

        func performSave(with imageURL: String?) {
            let finalUpdate = ClientProfileUpdatePayload(
                full_name: fullName,
                age: age,
                gender: gender,
                // Keep backend RPC compatibility while removing goal from editable UI.
                goal: profile?.goal ?? makeProfileSummary(age: age, gender: gender),
                profile_image_url: imageURL
            )

            ClientProfileService.shared.updateProfile(finalUpdate) { [weak self] error in
                DispatchQueue.main.async {
                    self?.loader?.hide()
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
                        self?.loader?.hide()
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
        genderOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        genderOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard genderOptions.indices.contains(row) else { return }
        genderTextField.text = genderOptions[row]
        if let age = Int(phoneTextField.text ?? "") {
            goalTextField.text = makeProfileSummary(age: age, gender: genderOptions[row])
        } else {
            goalTextField.text = makeProfileSummary(age: nil, gender: genderOptions[row])
        }
    }

    @objc private func donePickingGender() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        guard genderOptions.indices.contains(selectedRow) else {
            view.endEditing(true)
            return
        }
        genderTextField.text = genderOptions[selectedRow]
        if let age = Int(phoneTextField.text ?? "") {
            goalTextField.text = makeProfileSummary(age: age, gender: genderOptions[selectedRow])
        } else {
            goalTextField.text = makeProfileSummary(age: nil, gender: genderOptions[selectedRow])
        }
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

    private func makeProfileSummary(age: Int?, gender: String?) -> String {
        var parts: [String] = []
        if let gender, !gender.isEmpty {
            parts.append(gender)
        }
        if let age {
            parts.append("Age \(age)")
        }
        return parts.isEmpty ? "Client" : parts.joined(separator: " • ")
    }

    // MARK: - Permissions
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            showPermissionAlert(for: "Camera")
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status == .authorized || status == .limited)
                }
            }
        case .denied, .restricted:
            showPermissionAlert(for: "Photo Library")
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func showPermissionAlert(for feature: String) {
        let alert = UIAlertController(
            title: "\(feature) Permission Needed",
            message: "Please enable \(feature) access in Settings to change your profile picture.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }
}
