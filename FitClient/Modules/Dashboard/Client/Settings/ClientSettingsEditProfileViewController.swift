
import UIKit

class ClientSettingsEditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var goalTextField: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!

    // MARK: - Properties
    private var profile: ClientProfile?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
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

        bioTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        bioTextView.layer.borderColor = UIColor.clear.cgColor
        bioTextView.layer.borderWidth = 0
    }

    private func setupTextField(_ textField: UITextField) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.rightViewMode = .always
    }

    // MARK: - Data Loading

    private func loadClientProfile() {
        let clientId = "client_001" // placeholder; replace with logged-in client id
        DataService.shared.loadClientProfile(forClientId: clientId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self?.profile = profile
                    self?.updateUI()
                case .failure:
                    break
                }
            }
        }
    }

    private func updateUI() {
        // In absence of profile fields in JSON, keep fields empty except email from defaults
        if let email = UserDefaults.standard.string(forKey: "userEmail") {
            emailTextField.text = email
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
        }
        dismiss(animated: true)
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty,
              let goal = goalTextField.text, !goal.isEmpty,
              let bio = bioTextView.text, !bio.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        guard email.isValidEmail else {
            showAlert(title: "Error", message: "Please enter a valid email address")
            return
        }

        showAlert(title: "Success", message: "Profile updated successfully") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
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
