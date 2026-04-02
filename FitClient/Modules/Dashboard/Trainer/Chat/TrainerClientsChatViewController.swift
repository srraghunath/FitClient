

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
    private var trainerContext: ParticipantContext?
    private var messages: [ChatMessage] = []
    private var conversation: Conversation?
    private var realtimeChannel: RealtimeChannelV2?
    private var pollingTask: Task<Void, Never>?
    private var blockedUserIds: Set<UUID> = []
    private var otherParticipantUserId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupMessageInput()
        requestUGCAccessAndLoad()
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
                if let client = try? await ChatService.shared.fetchClient(by: clientUUID) {
                    self.otherParticipantUserId = client.userId
                }
                let conversation = try await ChatService.shared.ensureConversationForTrainer(clientId: clientUUID)
                let dbMessages = try await ChatService.shared.fetchMessages(conversationId: conversation.id)
                let mapped: [ChatMessage] = dbMessages
                    .filter { self.blockedUserIds.contains($0.senderId) == false }
                    .map { self.mapDBMessage($0) }
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
        guard let rawText = messageInputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !rawText.isEmpty else { return }
        guard let conversation else { return }

        if let otherParticipantUserId, blockedUserIds.contains(otherParticipantUserId) {
            showAlert(title: "User Blocked", message: "You have blocked this user.")
            return
        }

        let text: String
        do {
            text = try SafetyModerationService.shared.validateOutgoingMessage(rawText)
        } catch {
            showAlert(
                title: "Message Not Sent",
                message: "Message contains objectionable content and was blocked."
            )
            return
        }

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

    private func requestUGCAccessAndLoad() {
        SafetyModerationService.shared.ensureTermsAcceptedBeforeUGC(presenter: self) { [weak self] accepted in
            guard let self else { return }
            guard accepted else {
                self.navigationController?.popViewController(animated: true)
                return
            }

            Task { [weak self] in
                guard let self else { return }
                await self.refreshBlockedUsers()
                await MainActor.run {
                    self.applyBlockedStateToComposer()
                }
                self.loadMessages()
                self.trainerContext = try? await ChatService.shared.fetchTrainerContextForCurrentUser()
            }
        }
    }

    private func refreshBlockedUsers() async {
        do {
            blockedUserIds = try await SafetyModerationService.shared.fetchBlockedUserIds()
        } catch {
            print("[TrainerClientsChatViewController] Failed to fetch blocked users: \(error)")
        }
    }

    private func applyBlockedStateToComposer() {
        guard let otherParticipantUserId else { return }
        let isBlocked = blockedUserIds.contains(otherParticipantUserId)
        messageInputField.isEnabled = !isBlocked
        sendButton.isEnabled = !isBlocked
        messageInputField.placeholder = isBlocked ? "You blocked this user" : "Type a message"
    }

    private func presentModerationSheet(for message: ChatMessage) {
        let sheet = UIAlertController(title: "Safety", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Report", style: .default) { [weak self] _ in
            self?.presentReportReasonPicker(message: message)
        })
        sheet.addAction(UIAlertAction(title: "Block User", style: .destructive) { [weak self] _ in
            self?.presentBlockReasonPicker(message: message)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }

        present(sheet, animated: true)
    }

    private func presentReportReasonPicker(message: ChatMessage) {
        let picker = UIAlertController(title: "Report Message", message: "Select a reason.", preferredStyle: .actionSheet)
        for reason in ContentReportReason.allCases {
            picker.addAction(UIAlertAction(title: reason.rawValue, style: .default) { [weak self] _ in
                self?.report(message: message, reason: reason)
            })
        }
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = picker.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(picker, animated: true)
    }

    private func presentBlockReasonPicker(message: ChatMessage) {
        let picker = UIAlertController(title: "Block User", message: "Blocking reports this user to FitBond and hides their messages instantly.", preferredStyle: .actionSheet)
        for reason in ContentReportReason.allCases {
            picker.addAction(UIAlertAction(title: reason.rawValue, style: .destructive) { [weak self] _ in
                self?.block(message: message, reason: reason)
            })
        }
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = picker.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(picker, animated: true)
    }

    private func report(message: ChatMessage, reason: ContentReportReason) {
        guard
            let conversation,
            let reportedUserId = UUID(uuidString: message.senderId)
        else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await SafetyModerationService.shared.submitContentReport(
                    reportedUserId: reportedUserId,
                    messageId: UUID(uuidString: message.id),
                    conversationId: conversation.id,
                    reason: reason,
                    details: message.message
                )
                await MainActor.run {
                    self.showAlert(
                        title: "Report Submitted",
                        message: "Thanks. Our team reviews reports within 24 hours."
                    )
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Could not submit report. Please try again.")
                }
            }
        }
    }

    private func block(message: ChatMessage, reason: ContentReportReason) {
        guard
            let conversation,
            let blockedUserId = UUID(uuidString: message.senderId)
        else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await SafetyModerationService.shared.blockUserAndReport(
                    blockedUserId: blockedUserId,
                    reason: reason,
                    details: message.message,
                    messageId: UUID(uuidString: message.id),
                    conversationId: conversation.id
                )

                await MainActor.run {
                    self.blockedUserIds.insert(blockedUserId)
                    self.messages.removeAll { $0.senderId == blockedUserId.uuidString }
                    self.tableView.reloadData()
                    self.applyBlockedStateToComposer()
                    self.showAlert(
                        title: "User Blocked",
                        message: "This user has been blocked and reported to FitBond."
                    )
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Could not block user. Please try again.")
                }
            }
        }
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
                if self.blockedUserIds.contains(dbMessage.senderId) { return }
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
                        self.blockedUserIds.contains(db.senderId) == false
                            && self.messages.contains(where: { $0.id == db.id.uuidString }) == false
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
        let resolvedName: String
        if let senderName = db.senderName, senderName.isEmpty == false {
            resolvedName = senderName
        } else {
            resolvedName = db.isFromTrainer ? (trainerContext?.name ?? "Trainer") : (clientName ?? "Client")
        }

        let resolvedImage: String
        if let image = db.senderImage, image.isEmpty == false {
            resolvedImage = image
        } else {
            resolvedImage = db.isFromTrainer ? (trainerContext?.imageURL ?? "") : (clientImage ?? "")
        }

        return ChatMessage(
            id: db.id.uuidString,
            senderId: db.senderId.uuidString,
            senderName: resolvedName,
            senderImage: resolvedImage,
            message: SafetyModerationService.shared.sanitizeForDisplay(db.text),
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

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let message = messages[indexPath.row]
        guard message.isClient else { return nil }

        let report = UIContextualAction(style: .normal, title: "Report") { [weak self] _, _, done in
            self?.presentReportReasonPicker(message: message)
            done(true)
        }
        report.backgroundColor = .systemOrange

        let block = UIContextualAction(style: .destructive, title: "Block") { [weak self] _, _, done in
            self?.presentBlockReasonPicker(message: message)
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [block, report])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard message.isClient else { return }
        presentModerationSheet(for: message)
    }
}

// MARK: - UITextFieldDelegate

extension TrainerClientsChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return false
    }
}
