//
//  ClientchatViewController.swift
//  FitClient
//
//  Created by admin6 on 13/11/25.
//

import UIKit

class ClientchatViewController: UIViewController {
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var messageInputTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerView: UIView!
    
    private var messages: [ChatMessage] = []
    private var currentUserName = "S R RAGHUNATH"
    private var currentUserImage = "https://via.placeholder.com/40x40?text=Client"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupMessageInput()
        loadChatsData()
        addKeyboardObservers()
    }
    
    deinit {
        removeKeyboardObservers()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        navigationController?.navigationBar.isHidden = true
        
        // Input field styling
        messageInputTextField.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        messageInputTextField.textColor = UIColor(red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        messageInputTextField.layer.cornerRadius = 12
        messageInputTextField.clipsToBounds = true
        messageInputTextField.delegate = self
        
        // Add left padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: messageInputTextField.frame.height))
        messageInputTextField.leftView = paddingView
        messageInputTextField.leftViewMode = .always
        
        // Set placeholder color
        if let placeholder = messageInputTextField.placeholder {
            messageInputTextField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)]
            )
        }
        
        // Send button styling
        sendButton.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        sendButton.tintColor = UIColor(red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        sendButton.layer.cornerRadius = 12
        sendButton.clipsToBounds = true
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        // Input container
        inputContainerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    }
    
    private func setupTableView() {
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        messagesTableView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        messagesTableView.separatorStyle = .none
        messagesTableView.estimatedRowHeight = 80
        messagesTableView.rowHeight = UITableView.automaticDimension
        
        messagesTableView.register(TrainerMessageCell.self, forCellReuseIdentifier: "TrainerMessageCell")
        messagesTableView.register(ClientMessageCell.self, forCellReuseIdentifier: "ClientMessageCell")
    }
    
    private func setupMessageInput() {
        messageInputTextField.returnKeyType = .send
    }
    
    private func loadChatsData() {
        guard let url = Bundle.main.url(forResource: "chatsData", withExtension: "json") else {
            print("Failed to locate chatsData.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decodedMessages = try decoder.decode([ChatMessage].self, from: data)
            messages = decodedMessages.sorted { $0.timestamp < $1.timestamp }
            messagesTableView.reloadData()
            scrollToBottom()
        } catch {
            print("Failed to decode chatsData.json: \(error)")
        }
    }
    
    @objc private func sendButtonTapped() {
        sendMessage()
    }
    
    private func sendMessage() {
        guard let messageText = messageInputTextField.text, !messageText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Create new message
        let newMessage = ChatMessage(
            id: "msg_\(UUID().uuidString.prefix(8))",
            senderId: "client_001",
            senderName: currentUserName,
            senderImage: currentUserImage,
            message: messageText,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            isClient: true
        )
        
        // Add to messages
        messages.append(newMessage)
        
        // Clear input
        messageInputTextField.text = ""
        
        // Reload table and scroll
        messagesTableView.beginUpdates()
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        messagesTableView.insertRows(at: [indexPath], with: .automatic)
        messagesTableView.endUpdates()
        
        scrollToBottom()
        
        // Simulate trainer response after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.simulateTrainerResponse()
        }
    }
    
    private func simulateTrainerResponse() {
        DataService.shared.loadChatResponses { [weak self] result in
            guard let self = self else { return }
            
            let randomResponse: String
            switch result {
            case .success(let responsesData):
                randomResponse = responsesData.trainerResponses.randomElement() ?? "Great work!"
            case .failure(let error):
                print("Failed to load chat responses: \(error)")
                randomResponse = "Great work!"
            }
            
            let trainerMessage = ChatMessage(
                id: "msg_\(UUID().uuidString.prefix(8))",
                senderId: "trainer_001",
                senderName: "DINESH",
                senderImage: "https://via.placeholder.com/40x40?text=Trainer",
                message: randomResponse,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                isClient: false
            )
            
            DispatchQueue.main.async {
                self.messages.append(trainerMessage)
                
                self.messagesTableView.beginUpdates()
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.messagesTableView.insertRows(at: [indexPath], with: .automatic)
                self.messagesTableView.endUpdates()
                
                self.scrollToBottom()
            }
        }
    }
    
    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
            messagesTableView.contentInset.bottom = bottomInset
            messagesTableView.verticalScrollIndicatorInsets.bottom = bottomInset
            scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        messagesTableView.contentInset.bottom = 0
        messagesTableView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ClientchatViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        if message.isClient {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ClientMessageCell", for: indexPath) as? ClientMessageCell else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TrainerMessageCell", for: indexPath) as? TrainerMessageCell else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            return cell
        }
    }
}

// MARK: - UITextFieldDelegate

extension ClientchatViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return false
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Codable {
    let id: String
    let senderId: String
    let senderName: String
    let senderImage: String
    let message: String
    let timestamp: String
    let isClient: Bool
    
    var timestampDate: Date {
        ISO8601DateFormatter().date(from: timestamp) ?? Date()
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestampDate)
    }
}

// MARK: - Trainer Message Cell

class TrainerMessageCell: UITableViewCell {
    
    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let messageBubble = UIView()
    private let messageLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        selectionStyle = .none
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(avatarImageView)
        
        // Name Label
        nameLabel.font = UIFont(name: "SFProDisplay-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        nameLabel.textColor = UIColor(red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Message Bubble
        messageBubble.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        messageBubble.layer.cornerRadius = 24
        messageBubble.clipsToBounds = true
        messageBubble.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageBubble)
        
        // Message Label
        messageLabel.font = UIFont(name: "SFProDisplay-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor(red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageBubble.addSubview(messageLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            
            messageBubble.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            messageBubble.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            messageBubble.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            messageLabel.leadingAnchor.constraint(equalTo: messageBubble.leadingAnchor, constant: 16),
            messageLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubble.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubble.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: ChatMessage) {
        nameLabel.text = message.senderName
        messageLabel.text = message.message
        
        // Load avatar
        if let url = URL(string: message.senderImage) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.avatarImageView.image = image
                    }
                }
            }.resume()
        }
    }
}

// MARK: - Client Message Cell

class ClientMessageCell: UITableViewCell {
    
    private let containerView = UIView()
    private let nameLabel = UILabel()
    private let messageBubble = UIView()
    private let messageLabel = UILabel()
    private let avatarImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        selectionStyle = .none
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Name Label
        nameLabel.font = UIFont(name: "SFProDisplay-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        nameLabel.textColor = UIColor(red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        nameLabel.textAlignment = .right
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Message Bubble
        messageBubble.backgroundColor = UIColor(red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
        messageBubble.layer.cornerRadius = 24
        messageBubble.clipsToBounds = true
        messageBubble.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageBubble)
        
        // Message Label
        messageLabel.font = UIFont(name: "SFProDisplay-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageBubble.addSubview(messageLabel)
        
        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = UIColor(red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802, alpha: 1.0)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(avatarImageView)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            avatarImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.trailingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            
            messageBubble.trailingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: -12),
            messageBubble.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageBubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            messageBubble.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            messageLabel.leadingAnchor.constraint(equalTo: messageBubble.leadingAnchor, constant: 16),
            messageLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubble.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubble.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: ChatMessage) {
        nameLabel.text = message.senderName
        messageLabel.text = message.message
        
        // Load avatar
        if let url = URL(string: message.senderImage) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.avatarImageView.image = image
                    }
                }
            }.resume()
        }
    }
}
