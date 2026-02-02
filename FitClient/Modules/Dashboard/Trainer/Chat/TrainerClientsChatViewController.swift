

import UIKit
import Supabase

class TrainerClientsChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageInputField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerBottom: NSLayoutConstraint!
    @IBOutlet weak var inputContainerView: UIView!

    var clientId: String?
    var clientName: String?
    var clientImage: String?
    private var messages: [ChatMessage] = []
    private var conversation: Conversation?
    private var realtimeChannel: RealtimeChannelV2?
    private var pollingTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupMessageInput()
        loadMessages()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        NotificationCenter.default.removeObserver(self)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    @IBAction private func backTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    deinit {
        Task { [realtimeChannel] in
            await realtimeChannel?.unsubscribe()
        }
        realtimeChannel = nil
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        navigationController?.navigationBar.isHidden = true

        // Input styling to mirror the client chat screen
        messageInputField.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        messageInputField.textColor = UIColor(
            red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        messageInputField.layer.cornerRadius = 12
        messageInputField.clipsToBounds = true
        messageInputField.delegate = self

        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: 16, height: messageInputField.frame.height))
        messageInputField.leftView = paddingView
        messageInputField.leftViewMode = .always

        if let placeholder = messageInputField.placeholder {
            messageInputField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor(
                        red: 0.84705882352941, green: 0.80000000000000,
                        blue: 0.78431372549019, alpha: 1.0)
                ]
            )
        }

        sendButton.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        sendButton.tintColor = UIColor(
            red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        sendButton.layer.cornerRadius = 12
        sendButton.clipsToBounds = true
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.setTitle(nil, for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        inputContainerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    }

    private func setupTableView() {
        tableView.register(TrainerMessageCell.self, forCellReuseIdentifier: "TrainerMessageCell")
        tableView.register(ClientMessageCell.self, forCellReuseIdentifier: "ClientMessageCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func setupMessageInput() {
        messageInputField.returnKeyType = .send
    }
    
    private func loadMessages() {
        guard let clientId = clientId, let clientUUID = UUID(uuidString: clientId) else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let conversation = try await ChatService.shared.ensureConversationForTrainer(clientId: clientUUID)
                let dbMessages = try await ChatService.shared.fetchMessages(conversationId: conversation.id)
                let mapped: [ChatMessage] = dbMessages.map { self.mapDBMessage($0) }
                await MainActor.run {
                    self.conversation = conversation
                    self.messages = mapped
                    self.tableView.reloadData()
                    self.scrollToBottom()
                    self.startRealtime(for: conversation.id)
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
                let message = ChatMessage(
                    id: dbMessage.id.uuidString,
                    senderId: dbMessage.senderId.uuidString,
                    senderName: dbMessage.senderName ?? trainerContext.name,
                    senderImage: dbMessage.senderImage ?? trainerContext.imageURL ?? "",
                    message: dbMessage.text,
                    timestamp: ChatService.shared.isoString(from: dbMessage.timestamp),
                    isClient: false
                )

                await MainActor.run {
                    if self.messages.contains(where: { $0.id == message.id }) == false {
                        self.messages.append(message)
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
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

// MARK: - Realtime

private extension TrainerClientsChatViewController {
    func startRealtime(for conversationId: UUID) {
        realtimeChannel = ChatService.shared.subscribeToMessages(conversationId: conversationId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let dbMessage):
                // Avoid duplicates when the sender is this trainer
                if self.messages.contains(where: { $0.id == dbMessage.id.uuidString }) { return }

                let message = self.mapDBMessage(dbMessage)

                Task { @MainActor in
                    self.messages.append(message)
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            case .failure(let error):
                print("[TrainerClientsChatViewController] Realtime error: \(error)")
                self.startPolling(for: conversationId)
            }
        }
    }

    func startPolling(for conversationId: UUID) {
        pollingTask?.cancel()

        let latestDate = messages.last?.timestampDate

        pollingTask = ChatService.shared.startPollingMessages(
            conversationId: conversationId,
            lastTimestamp: latestDate,
            interval: 10
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let dbMessages):
                let newMessages: [ChatMessage] = dbMessages
                    .filter { db in
                        self.messages.contains(where: { $0.id == db.id.uuidString }) == false
                    }
                    .map { self.mapDBMessage($0) }

                if newMessages.isEmpty { return }

                Task { @MainActor in
                    self.messages.append(contentsOf: newMessages)
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            case .failure(let error):
                print("[TrainerClientsChatViewController] Polling error: \(error)")
            }
        }
    }

    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    func mapDBMessage(_ db: DBMessage) -> ChatMessage {
        ChatMessage(
            id: db.id.uuidString,
            senderId: db.senderId.uuidString,
            senderName: db.senderName ?? "",
            senderImage: db.senderImage ?? "",
            message: db.text,
            timestamp: ChatService.shared.isoString(from: db.timestamp),
            isClient: db.isFromTrainer == false
        )
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension TrainerClientsChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

        // On trainer side: trainer's own messages should appear on the right (green),
        // and client messages on the left (dark). So we invert which bubble we use
        // compared to the client app.
        if message.isClient {
            // Message from client → left, dark bubble
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "TrainerMessageCell", for: indexPath) as? TrainerMessageCell
            else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            return cell
        } else {
            // Message from trainer → right, green bubble
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "ClientMessageCell", for: indexPath) as? ClientMessageCell
            else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            return cell
        }
    }
}

// MARK: - UITextFieldDelegate

extension TrainerClientsChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return false
    }
}
