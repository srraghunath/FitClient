import UIKit

final class TrainerSettingsEditProfileViewController: UIViewController,
                                                     UIImagePickerControllerDelegate,
                                                     UINavigationControllerDelegate,
                                                     UIPickerViewDelegate,
                                                     UIPickerViewDataSource {

    // MARK: - IBOutlets
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var ageTextField: UITextField!
    @IBOutlet private weak var genderTextField: UITextField!
    @IBOutlet private weak var specializationTextField: UITextField!
    @IBOutlet private weak var saveButton: UIButton!

    // MARK: - Properties
    private let genderPicker = UIPickerView()
    private var genderOptions: [String] = []
    private var loader: ActivityLoader?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGenderPicker()
        loadGenderOptions()
        fetchProfile()
    }

    // MARK: - UI Setup
    private func setupUI() {
        title = "Edit Profile"

        view.backgroundColor = .backgroundBlack

        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.primaryGreen.cgColor
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        )

        configureTextFields()
        emailTextField.isUserInteractionEnabled = false
        saveButton.applyPrimaryStyle(title: "Save Changes")
    }

    private func configureTextFields() {
        let fields: [(UITextField, String)] = [
            (nameTextField, "Full Name"),
            (emailTextField, "Email"),
            (ageTextField, "Age"),
            (genderTextField, "Gender"),
            (specializationTextField, "Specialization")
        ]

        fields.forEach { field, placeholder in
            field.borderStyle = .none
            field.applyAppStyle(placeholder: placeholder)
            field.keyboardAppearance = .dark
        }
    }

    private func setupGenderPicker() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        genderTextField.inputView = genderPicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.setItems(
            [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(
                    title: "Done", style: .done, target: self, action: #selector(donePickingGender))
            ],
            animated: false
        )
        genderTextField.inputAccessoryView = toolbar
    }

    // MARK: - Fetch Profile
    private func fetchProfile() {
        print("[TrainerSettingsEditProfile] Fetching trainer profile via Supabase...")
        TrainerService.shared.fetchTrainerProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    print("[TrainerSettingsEditProfile] Fetched profile: name=\(profile.fullName) image=\(profile.profileImageURL ?? "nil")")
                    self?.populateUI(with: profile)
                case .failure(let error):
                    print("[TrainerSettingsEditProfile] Failed to fetch profile: \(error)")
                    self?.showAlert(
                        title: "Error",
                        message: "Failed to load profile: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    private func loadGenderOptions() {
        DataService.shared.loadSignupOptions { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let options):
                    self?.genderOptions = options.genderOptions
                    self?.genderPicker.reloadAllComponents()
                    self?.alignGenderPickerWithCurrentSelection()
                case .failure(let error):
                    print("[TrainerSettingsEditProfile] Failed to load gender options: \(error)")
                }
            }
        }
    }

    private func populateUI(with profile: TrainerProfile) {
        nameTextField.text = profile.fullName
        emailTextField.text = AuthService.shared.supabase.auth.currentUser?.email
        if let age = profile.age { ageTextField.text = String(age) }
        genderTextField.text = profile.gender
        specializationTextField.text = profile.specialization

        alignGenderPickerWithCurrentSelection()

        if let urlString = profile.profileImageURL,
           let url = URL(string: urlString) {
            print("[TrainerSettingsEditProfile] Loading profile image from URL: \(urlString)")
            loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }

    // MARK: - Actions
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

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        guard let user = AuthService.shared.supabase.auth.currentUser else {
            print("[TrainerSettingsEditProfile] No authenticated user; aborting save")
            showAlert(title: "Error", message: "Please log in again and retry")
            return
        }

        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Error", message: "Name cannot be empty")
            return
        }

        let userId = user.id
        print("[TrainerSettingsEditProfile] Preparing save for userId=\(userId)")

        let age = Int(ageTextField.text ?? "")
        let gender = genderTextField.text
        let specialization = specializationTextField.text

        loader = ActivityLoader.show(over: view)

        if let image = profileImageView.image {
            uploadImageAndSave(
                image: image,
                userId: userId,
                name: name,
                age: age,
                gender: gender,
                specialization: specialization
            )
        } else {
            saveProfile(
                imageURL: nil,
                userId: userId,
                name: name,
                age: age,
                gender: gender,
                specialization: specialization
            )
        }
    }

    // MARK: - Save Helpers
    private func uploadImageAndSave(
        image: UIImage,
        userId: UUID,
        name: String,
        age: Int?,
        gender: String?,
        specialization: String?
    ) {
        print("[TrainerSettingsEditProfile] Uploading profile image for userId=\(userId)")
        TrainerService.shared.uploadProfileImage(image, for: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    print("[TrainerSettingsEditProfile] Image uploaded. Public URL=\(url)")
                    self?.saveProfile(
                        imageURL: url,
                        userId: userId,
                        name: name,
                        age: age,
                        gender: gender,
                        specialization: specialization
                    )
                case .failure(let error):
                    print("[TrainerSettingsEditProfile] Image upload failed: \(error)")
                    self?.showAlert(
                        title: "Error",
                        message: error.localizedDescription
                    )
                    self?.loader?.hide()
                }
            }
        }
    }

    private func saveProfile(
        imageURL: String?,
        userId: UUID,
        name: String,
        age: Int?,
        gender: String?,
        specialization: String?
    ) {
        let update = TrainerProfileUpdate(
            full_name: name,
            age: age,
            gender: gender,
            specialization: specialization,
            profile_image_url: imageURL
        )

        print("[TrainerSettingsEditProfile] Saving profile for userId=\(userId) imageURL=\(imageURL ?? "nil")")

        TrainerService.shared.updateTrainerProfile(update, for: userId) { [weak self] error in
            DispatchQueue.main.async {
                self?.loader?.hide()
                if let error {
                    print("[TrainerSettingsEditProfile] Save failed: \(error)")
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    print("[TrainerSettingsEditProfile] Save succeeded")
                    self?.showAlert(title: "Success", message: "Profile updated") {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Image Picker
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let image = info[.editedImage] as? UIImage
            ?? info[.originalImage] as? UIImage {
            profileImageView.image = image
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
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

    private func alignGenderPickerWithCurrentSelection() {
        guard !genderOptions.isEmpty else { return }

        let currentGender = genderTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let currentGender,
           let index = genderOptions.firstIndex(where: { $0.caseInsensitiveCompare(currentGender) == .orderedSame }) {
            genderPicker.selectRow(index, inComponent: 0, animated: false)
            genderTextField.text = genderOptions[index]
        } else {
            genderPicker.selectRow(0, inComponent: 0, animated: false)
            if (currentGender ?? "").isEmpty {
                genderTextField.text = genderOptions.first
            }
        }
    }
}

// MARK: - UIPickerViewDataSource

extension TrainerSettingsEditProfileViewController {
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
    }
}
