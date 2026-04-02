//
//  ClientchatViewController.swift
//  FitClient
//
//  Created by admin6 on 13/11/25.
//

import Supabase
import UIKit

class ClientchatViewController: UIViewController {

    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var messageInputTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputContainerBottom: NSLayoutConstraint!

    private var messages: [ChatMessage] = []
    private var conversation: Conversation?
    private var realtimeChannel: RealtimeChannelV2?
    private var pollingTask: Task<Void, Never>?
    private var clientContext: ParticipantContext?
    private var trainerDisplayName: String?
    private var trainerImageURL: String?
    private var clientDisplayName: String?
    private var clientImageURL: String?
    private var blockedUserIds: Set<UUID> = []
    private var otherParticipantUserId: UUID?
    private lazy var blockedOverlayView: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = .black
        overlay.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stack)
        
        let label = UILabel()
        label.text = "You have blocked this user"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .medium)
        stack.addArrangedSubview(label)
        
        let button = UIButton(type: .system)
        button.setTitle("Unblock", for: .normal)
        button.backgroundColor = .primaryGreen
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: #selector(unblockTapped), for: .touchUpInside)
        stack.addArrangedSubview(button)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        
        return overlay
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupMessageInput()
        requestUGCAccessAndLoad()
        addKeyboardObservers()
        addDismissTapGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        Task { [weak self] in
            guard let self else { return }
            await self.refreshBlockedUsers()
            await MainActor.run {
                self.applyBlockedStateToComposer()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    deinit {
        removeKeyboardObservers()
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

        // Input field styling
        messageInputTextField.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        messageInputTextField.textColor = UIColor(
            red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        messageInputTextField.layer.cornerRadius = 12
        messageInputTextField.clipsToBounds = true
        messageInputTextField.delegate = self

        // Add left padding to text field
        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: 16, height: messageInputTextField.frame.height))
        messageInputTextField.leftView = paddingView
        messageInputTextField.leftViewMode = .always

        // Set placeholder color
        if let placeholder = messageInputTextField.placeholder {
            messageInputTextField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor(
                        red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019,
                        alpha: 1.0)
                ]
            )
        }

        // Send button styling
        sendButton.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        sendButton.tintColor = UIColor(
            red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
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
        messagesTableView.contentInsetAdjustmentBehavior = .never

        messagesTableView.register(
            TrainerMessageCell.self, forCellReuseIdentifier: "TrainerMessageCell")
        messagesTableView.register(
            ClientMessageCell.self, forCellReuseIdentifier: "ClientMessageCell")
    }

    private func setupMessageInput() {
        messageInputTextField.returnKeyType = .send
    }

    private func addDismissTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func loadConversationAndMessages() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let conversation = try await ChatService.shared.ensureConversationForCurrentClient()
                self.otherParticipantUserId = conversation.trainerId
                let dbMessages = try await ChatService.shared.fetchMessages(conversationId: conversation.id)

                // Best-effort participant details; do not fail if missing
                if let clientCtx = try? await ChatService.shared.fetchClientContextForCurrentUser() {
                    self.clientContext = clientCtx
                    self.clientDisplayName = clientCtx.name
                    self.clientImageURL = clientCtx.imageURL
                }

                if let trainerRow = try? await ChatService.shared.fetchTrainer(by: conversation.trainerId) {
                    self.trainerDisplayName = trainerRow.fullName ?? "Trainer"
                    self.trainerImageURL = trainerRow.profileImageURL
                        ?? ChatService.shared.defaultProfileImageURL(for: trainerRow.id)
                }

                if let clientRow = try? await ChatService.shared.fetchClient(by: conversation.clientId) {
                    self.clientDisplayName = clientRow.fullName ?? self.clientDisplayName ?? "Client"
                    if self.clientImageURL == nil {
                        self.clientImageURL = clientRow.profileImageURL
                            ?? ChatService.shared.defaultProfileImageURL(for: clientRow.userId)
                    }
                }

                let mapped = dbMessages
                    .filter { self.blockedUserIds.contains($0.senderId) == false }
                    .map { self.mapDBMessage($0) }
                await MainActor.run {
                    self.conversation = conversation
                    self.applyBlockedStateToComposer()
                    self.messages = mapped
                    self.messagesTableView.reloadData()
                    self.scrollToBottom()
                    self.startRealtime(for: conversation.id)
                }
            } catch {
                print("[ClientchatViewController] Failed to load conversation/messages: \(error)")
            }
        }
    }

    @objc private func sendButtonTapped() {
        sendMessage()
    }

    private func sendMessage() {
        guard let rawText = messageInputTextField.text,
            !rawText.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            print("⚠️ [ClientChat] Empty message, aborting")
            return
        }

        if let otherParticipantUserId, blockedUserIds.contains(otherParticipantUserId) {
            let alert = UIAlertController(
                title: "User Blocked",
                message: "You have blocked this user. Unblock if you want to chat again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Unblock", style: .default) { [weak self] _ in
                self?.performUnblock(userId: otherParticipantUserId)
            })
            present(alert, animated: true)
            return
        }

        let messageText: String
        do {
            messageText = try SafetyModerationService.shared.validateOutgoingMessage(rawText)
        } catch {
            showAlert(
                title: "Message Not Sent",
                message: "Message contains objectionable content and was blocked."
            )
            return
        }

        guard let conversation else {
            print("🔴 [ClientChat] Conversation is NIL, cannot send")
            return
        }

        print("🟢 [ClientChat] Sending message:", messageText)
        print("   ↳ conversationId:", conversation.id)

        messageInputTextField.text = ""

        Task {
            do {
                let clientContext: ParticipantContext
                if let cached = self.clientContext {
                    clientContext = cached
                } else {
                    let fetched = try await ChatService.shared.fetchClientContextForCurrentUser()
                    self.clientContext = fetched
                    clientContext = fetched
                }
                print("🟡 [ClientChat] Client context loaded:", clientContext.userId)

                let dbMessage = try await ChatService.shared.sendMessage(
                    conversationId: conversation.id,
                    text: messageText,
                    isFromTrainer: false,
                    senderName: clientContext.name,
                    senderImage: clientContext.imageURL
                )

                print("✅ [ClientChat] Message INSERTED to DB")
                print("   ↳ id:", dbMessage.id)
                print("   ↳ text:", dbMessage.text)

                let chatMessage = self.mapDBMessage(dbMessage)

                await MainActor.run {
                    // Optimistic insert to avoid waiting on realtime echo.
                    if self.messages.contains(where: { $0.id == chatMessage.id }) == false {
                        self.messages.append(chatMessage)
                        self.messagesTableView.reloadData()
                        self.scrollToBottom()
                    }
                }

            } catch {
                print("🔴 [ClientChat] FAILED to send message:", error)
            }
        }
    }

    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func mapDBMessage(_ db: DBMessage) -> ChatMessage {
        let name = nonEmpty(db.senderName)
            ?? (db.isFromTrainer ? (trainerDisplayName ?? "Trainer") : (clientDisplayName ?? "Client"))
        let image = nonEmpty(db.senderImage)
            ?? (db.isFromTrainer ? (trainerImageURL ?? "") : (clientImageURL ?? ""))

        return ChatMessage(
            id: db.id.uuidString,
            senderId: db.senderId.uuidString,
            senderName: name,
            senderImage: image,
            message: SafetyModerationService.shared.sanitizeForDisplay(db.text),
            timestamp: ChatService.shared.isoString(from: db.timestamp),
            isClient: db.isFromTrainer == false
        )
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, value.isEmpty == false else { return nil }
        return value
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
                self.loadConversationAndMessages()
            }
        }
    }

    private func refreshBlockedUsers() async {
        do {
            blockedUserIds = try await SafetyModerationService.shared.fetchBlockedUserIds()
        } catch {
            print("[ClientchatViewController] Failed to fetch blocked users: \(error)")
        }
    }

    private func applyBlockedStateToComposer() {
        guard let otherParticipantUserId else { return }
        let isBlocked = blockedUserIds.contains(otherParticipantUserId)
        
        if isBlocked {
            if blockedOverlayView.superview == nil {
                view.addSubview(blockedOverlayView)
                NSLayoutConstraint.activate([
                    blockedOverlayView.topAnchor.constraint(equalTo: messagesTableView.topAnchor),
                    blockedOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    blockedOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    blockedOverlayView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor)
                ])
            }
            blockedOverlayView.isHidden = false
            view.bringSubviewToFront(blockedOverlayView)
        } else {
            blockedOverlayView.isHidden = true
        }

        messageInputTextField.isEnabled = !isBlocked
        sendButton.isEnabled = !isBlocked
        messageInputTextField.placeholder = isBlocked ? "You blocked this user" : "Type a message"
    }

    @objc private func unblockTapped() {
        guard let otherParticipantUserId else { return }
        
        let alert = UIAlertController(
            title: "Unblock User?",
            message: "You will be able to see their messages and chat again.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unblock", style: .default) { [weak self] _ in
            self?.performUnblock(userId: otherParticipantUserId)
        })
        
        present(alert, animated: true)
    }

    private func performUnblock(userId: UUID) {
        print("👆 [ClientChat] User clicked UNBLOCK for ID: \(userId.uuidString)")
        // 1. Optimistic local update
        self.blockedUserIds.remove(userId)
        self.applyBlockedStateToComposer()
        
        Task { [weak self] in
            guard let self else { return }
            do {
                // 2. Perform background sync
                try await SafetyModerationService.shared.unblockUser(blockedUserId: userId)
                
                // 3. Robust final refresh to ensure truth
                await self.refreshBlockedUsers()
                
                await MainActor.run {
                    self.applyBlockedStateToComposer()
                    self.messages.removeAll()
                    self.loadConversationAndMessages()
                }
            } catch {
                // 4. Rollback on failure
                await MainActor.run {
                    self.blockedUserIds.insert(userId)
                    self.applyBlockedStateToComposer()
                    self.showAlert(title: "Error", message: "Could not unblock user: \(error.localizedDescription)")
                }
            }
        }
    }

    private func presentModerationSheet(for message: ChatMessage) {
        guard let senderId = UUID(uuidString: message.senderId) else { return }
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
        print("[ClientchatViewController] Opened moderation sheet for sender=\(senderId)")
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
                    self.messagesTableView.reloadData()
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

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
    guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    inputContainerBottom.constant = frame.height - view.safeAreaInsets.bottom
    UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    scrollToBottom()
}

@objc private func keyboardWillHide(notification: NSNotification) {
    inputContainerBottom.constant = 0
    UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
}
}

// MARK: - Realtime

extension ClientchatViewController {
    fileprivate func startRealtime(for conversationId: UUID) {
        print("🟢 [ClientChat] Starting realtime for:", conversationId)

        realtimeChannel = ChatService.shared.subscribeToMessages(
            conversationId: conversationId
        ) { [weak self] result in
            guard let self else { return }

            print("🟣 [ClientChat] Realtime callback FIRED")

            switch result {
            case .success(let dbMessage):
                print("🟢 [ClientChat] Realtime message received:", dbMessage.id)

                if self.blockedUserIds.contains(dbMessage.senderId) {
                    return
                }

                if self.messages.contains(where: { $0.id == dbMessage.id.uuidString }) {
                    print("⚠️ [ClientChat] Duplicate message ignored:", dbMessage.id)
                    return
                }

                let chatMessage = self.mapDBMessage(dbMessage)

                Task { @MainActor in
                    print("🧵 [ClientChat] Updating UI with message:", chatMessage.id)
                    self.messages.append(chatMessage)
                    self.messagesTableView.reloadData()
                    self.scrollToBottom()
                }

            case .failure(let error):
                print("🔴 [ClientChat] Realtime error:", error)
                self.startPolling(for: conversationId)
            }
        }
    }

    fileprivate func startPolling(for conversationId: UUID) {
        pollingTask?.cancel()

        let lastTimestamp = messages.last?.timestampDate
        pollingTask = ChatService.shared.startPollingMessages(
            conversationId: conversationId,
            lastTimestamp: lastTimestamp,
            interval: 10
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let dbMessages):
                let newMessages = dbMessages
                    .filter { db in
                        self.blockedUserIds.contains(db.senderId) == false
                            && self.messages.contains(where: { $0.id == db.id.uuidString }) == false
                    }
                    .map { self.mapDBMessage($0) }

                if newMessages.isEmpty { return }

                Task { @MainActor in
                    self.messages.append(contentsOf: newMessages)
                    self.messagesTableView.reloadData()
                    self.scrollToBottom()
                }
            case .failure(let error):
                print("[ClientchatViewController] Polling error:", error)
            }
        }
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
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "ClientMessageCell", for: indexPath) as? ClientMessageCell
            else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            return cell
        } else {
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: "TrainerMessageCell", for: indexPath) as? TrainerMessageCell
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
        guard message.isClient == false else { return nil }

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
        guard message.isClient == false else { return }
        presentModerationSheet(for: message)
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
        avatarImageView.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(avatarImageView)

        // Name Label
        nameLabel.font =
            UIFont(name: "SFProDisplay-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        nameLabel.textColor = UIColor(
            red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)

        // Message Bubble
        messageBubble.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        messageBubble.layer.cornerRadius = 24
        messageBubble.clipsToBounds = true
        messageBubble.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageBubble)

        // Message Label
        messageLabel.font =
            UIFont(name: "SFProDisplay-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor(
            red: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageBubble.addSubview(messageLabel)

        // Constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),

            messageBubble.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor, constant: 12),
            messageBubble.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageBubble.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            messageBubble.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            messageLabel.leadingAnchor.constraint(
                equalTo: messageBubble.leadingAnchor, constant: 16),
            messageLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(
                equalTo: messageBubble.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(
                equalTo: messageBubble.bottomAnchor, constant: -12),
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
        nameLabel.font =
            UIFont(name: "SFProDisplay-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        nameLabel.textColor = UIColor(
            red: 0.84705882352941, green: 0.80000000000000, blue: 0.78431372549019, alpha: 1.0)
        nameLabel.textAlignment = .right
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)

        // Message Bubble
        messageBubble.backgroundColor = UIColor(
            red: 0.68235294117647, green: 0.99607843137255, blue: 0.07843137254902, alpha: 1.0)
        messageBubble.layer.cornerRadius = 24
        messageBubble.clipsToBounds = true
        messageBubble.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageBubble)

        // Message Label
        messageLabel.font =
            UIFont(name: "SFProDisplay-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageBubble.addSubview(messageLabel)

        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = UIColor(
            red: 0.18823529411764706, green: 0.19215686274509802, blue: 0.19215686274509802,
            alpha: 1.0)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(avatarImageView)

        // Constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            avatarImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.trailingAnchor.constraint(
                equalTo: avatarImageView.leadingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),

            messageBubble.trailingAnchor.constraint(
                equalTo: avatarImageView.leadingAnchor, constant: -12),
            messageBubble.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            messageBubble.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            messageBubble.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            messageLabel.leadingAnchor.constraint(
                equalTo: messageBubble.leadingAnchor, constant: 16),
            messageLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(
                equalTo: messageBubble.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(
                equalTo: messageBubble.bottomAnchor, constant: -12),
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
