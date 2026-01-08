

import UIKit

class TrainerClientsChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageInputField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerBottom: NSLayoutConstraint!
    
    var clientId: String?
    var clientName: String?
    var clientImage: String?
    private var messages: [Message] = []
    private var conversation: Conversation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        setupInputField()
        loadMessages()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNavigationBar() {
        title = clientName ?? "Chat"
        navigationController?.navigationBar.tintColor = .primaryGreen
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "MessageTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .black
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    private func setupInputField() {
        messageInputField.applyAppStyle(placeholder: "Type a message...")
        sendButton.applyPrimaryStyle(title: "Send")
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }
    
    private func loadMessages() {
        guard let clientId = clientId, let clientUUID = UUID(uuidString: clientId) else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let conversation = try await ChatService.shared.ensureConversationForTrainer(clientId: clientUUID)
                let dbMessages = try await ChatService.shared.fetchMessages(conversationId: conversation.id)
                let mapped: [Message] = dbMessages.map { db in
                    Message(
                        id: db.id.uuidString,
                        senderId: db.senderId.uuidString,
                        senderName: db.senderName ?? "",
                        senderImage: db.senderImage ?? "",
                        text: db.text,
                        timestamp: ChatService.shared.isoString(from: db.timestamp),
                        isFromTrainer: db.isFromTrainer
                    )
                }
                await MainActor.run {
                    self.conversation = conversation
                    self.messages = mapped.reversed()
                    self.tableView.reloadData()
                }
            } catch {
                print("[TrainerClientsChatViewController] Failed to load messages: \(error)")
            }
        }
    }

    @objc private func sendTapped() {
        sendMessage()
    }

    private func sendMessage() {
        guard let text = messageInputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        guard let conversation else { return }
        messageInputField.text = ""

        Task { [weak self] in
            guard let self else { return }
            do {
                let trainerContext = try await ChatService.shared.fetchTrainerContextForCurrentUser()
                let dbMessage = try await ChatService.shared.sendMessage(
                    conversationId: conversation.id,
                    text: text,
                    isFromTrainer: true,
                    senderName: trainerContext.name,
                    senderImage: trainerContext.imageURL
                )
                let message = Message(
                    id: dbMessage.id.uuidString,
                    senderId: dbMessage.senderId.uuidString,
                    senderName: dbMessage.senderName ?? trainerContext.name,
                    senderImage: dbMessage.senderImage ?? trainerContext.imageURL ?? "",
                    text: dbMessage.text,
                    timestamp: ChatService.shared.isoString(from: dbMessage.timestamp),
                    isFromTrainer: true
                )

                await MainActor.run {
                    self.messages.insert(message, at: 0)
                    self.tableView.beginUpdates()
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    self.tableView.endUpdates()
                }
            } catch {
                print("[TrainerClientsChatViewController] Failed to send message: \(error)")
            }
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            inputContainerBottom.constant = keyboardFrame.height - view.safeAreaInsets.bottom
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        inputContainerBottom.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension TrainerClientsChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as? MessageTableViewCell else {
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        cell.configure(with: message)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}
