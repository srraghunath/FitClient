//
//  TrainerSettingsEditProfileViewController.swift
//  FitClient
//
//  Created by admin8 on 10/11/25.
//

import UIKit

class TrainerSettingsEditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var specializationTextField: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Properties
    private var trainer: Trainer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadTrainerData()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        //backButton.setTitle("Back", for: .normal)
        backButton.sizeToFit()
        backButton.tintColor = .primaryGreen
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup profile image
        profileImageView.layer.cornerRadius = 60
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.primaryGreen.cgColor
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = UIColor(hex: "#212121")
        
        // Setup text fields with padding
        setupTextField(nameTextField)
        setupTextField(emailTextField)
        setupTextField(phoneTextField)
        setupTextField(specializationTextField)
        
        // Setup bio text view
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
    
    private func loadTrainerData() {
        DataService.shared.loadTrainer { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let trainer):
                    self?.trainer = trainer
                    self?.updateUI(with: trainer)
                case .failure(let error):
                    print("Error loading trainer data: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Failed to load profile data")
                }
            }
        }
    }
    
    private func updateUI(with trainer: Trainer) {
        nameTextField.text = trainer.name
        emailTextField.text = trainer.email
        phoneTextField.text = trainer.phone
        specializationTextField.text = trainer.specialization
        bioTextView.text = trainer.bio
        
        // Load profile image
        if let url = URL(string: trainer.profileImage) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.profileImageView.image = image
                    }
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray
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
              let specialization = specializationTextField.text, !specialization.isEmpty,
              let bio = bioTextView.text, !bio.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }
        
        // Validate email
        guard email.isValidEmail else {
            showAlert(title: "Error", message: "Please enter a valid email address")
            return
        }
        
        // Show success message and pop back
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
