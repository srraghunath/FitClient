import Foundation
import Supabase

struct Conversation: Codable {
    let id: UUID
    let trainerId: UUID
    let clientId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId = "trainer_id"
        case clientId = "client_id"
        case createdAt = "created_at"
    }
}

struct ConversationInsert: Encodable {
    let trainer_id: UUID
    let client_id: UUID
}

struct DBMessage: Codable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let senderName: String?
    let senderImage: String?
    let text: String
    let timestamp: Date
    let isFromTrainer: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderImage = "sender_image"
        case text
        case timestamp
        case isFromTrainer = "is_from_trainer"
    }
}

struct MessageInsert: Encodable {
    let conversation_id: UUID
    let sender_id: UUID
    let sender_name: String?
    let sender_image: String?
    let text: String
    let is_from_trainer: Bool
}

struct ClientRow: Decodable {
    let id: UUID
    let userId: UUID
    let trainerId: UUID?
    let fullName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case trainerId = "trainer_id"
        case fullName = "full_name"
    }
}

struct TrainerRow: Decodable {
    let id: UUID
    let fullName: String?
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case profileImageURL = "profile_image_url"
    }
}

struct ParticipantContext {
    let userId: UUID
    let name: String
    let imageURL: String?
    let trainerId: UUID?
    let clientId: UUID?
}

final class ChatService {
    static let shared = ChatService()

    private let supabase = AuthService.shared.supabase
    private let isoFormatter = ISO8601DateFormatter()
    private let profileImagesBaseURL = URL(
        string: "https://xhxyhexaoxnejrsusfhb.supabase.co/storage/v1/object/public/profile-images")!

    private init() {}

    // MARK: - Public API (Client side)

    func ensureConversationForCurrentClient() async throws -> Conversation {
        let clientCtx = try await fetchClientContextForCurrentUser()
        guard let trainerId = clientCtx.trainerId, let clientId = clientCtx.clientId else {
            throw NSError(
                domain: "ChatService", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Trainer or client relationship missing"])
        }
        return try await ensureConversation(clientId: clientId, trainerId: trainerId)
    }

    // MARK: - Public API (Trainer side)

    func ensureConversationForTrainer(clientId: UUID) async throws -> Conversation {
        let trainerCtx = try await fetchTrainerContextForCurrentUser()
        return try await ensureConversation(clientId: clientId, trainerId: trainerCtx.userId)
    }

    func fetchMessages(conversationId: UUID) async throws -> [DBMessage] {
        try await fetchMessages(conversationId: conversationId, since: nil)
    }

    func fetchMessages(conversationId: UUID, since date: Date?) async throws -> [DBMessage] {
        var query = supabase
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)

        if let date {
            query = query.gt("timestamp", value: isoFormatter.string(from: date))
        }

        return try await query
            .order("timestamp", ascending: true)
            .execute()
            .value
    }

    func sendMessage(
        conversationId: UUID,
        text: String,
        isFromTrainer: Bool,
        senderName: String?,
        senderImage: String?
    ) async throws -> DBMessage {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(
                domain: "ChatService", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let payload = MessageInsert(
            conversation_id: conversationId,
            sender_id: userId,
            sender_name: senderName,
            sender_image: senderImage,
            text: text,
            is_from_trainer: isFromTrainer
        )

        let inserted: [DBMessage] =
            try await supabase
            .from("messages")
            .insert(payload)
            .select()
            .limit(1)
            .execute()
            .value

        guard let first = inserted.first else {
            throw NSError(
                domain: "ChatService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Insert returned no rows"])
        }
        return first
    }

    // MARK: - Helpers

    func isoString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    func defaultProfileImageURL(for userId: UUID) -> String {
        let idString = userId.uuidString.lowercased()
        return profileImagesBaseURL.appendingPathComponent("\(idString)/\(idString).jpg")
            .absoluteString
    }

    func fetchClientContextForCurrentUser() async throws -> ParticipantContext {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(
                domain: "ChatService", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let rows: [ClientRow] =
            try await supabase
            .from("clients")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let client = rows.first else {
            throw NSError(
                domain: "ChatService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Client record not found for current user"])
        }

        let name = client.fullName ?? "Client"
        let imageURL = defaultProfileImageURL(for: client.userId)
        return ParticipantContext(
            userId: client.userId, name: name, imageURL: imageURL, trainerId: client.trainerId,
            clientId: client.id)
    }

    func fetchTrainerContextForCurrentUser() async throws -> ParticipantContext {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(
                domain: "ChatService", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let rows: [TrainerRow] =
            try await supabase
            .from("trainers")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let trainer = rows.first else {
            throw NSError(
                domain: "ChatService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Trainer record not found"])
        }

        let name = trainer.fullName ?? "Trainer"
        let imageURL = trainer.profileImageURL ?? defaultProfileImageURL(for: trainer.id)
        return ParticipantContext(
            userId: trainer.id, name: name, imageURL: imageURL, trainerId: trainer.id, clientId: nil
        )
    }

    // MARK: - Private

    private func ensureConversation(clientId: UUID, trainerId: UUID) async throws -> Conversation {
        if let existing = try await findConversation(clientId: clientId) {
            return existing
        }

        let insert = ConversationInsert(trainer_id: trainerId, client_id: clientId)
        let created: [Conversation] =
            try await supabase
            .from("conversations")
            .insert(insert)
            .select()
            .limit(1)
            .execute()
            .value

        guard let conversation = created.first else {
            throw NSError(
                domain: "ChatService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create conversation"])
        }
        return conversation
    }

    private func findConversation(clientId: UUID) async throws -> Conversation? {
        let rows: [Conversation] =
            try await supabase
            .from("conversations")
            .select()
            .eq("client_id", value: clientId.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Realtime
    func subscribeToMessages(
        conversationId: UUID,
        onMessage: @escaping (Result<DBMessage, Error>) -> Void
    ) -> RealtimeChannelV2 {

        print("🟢 [Realtime] Creating channel for conversation:", conversationId)

        let channelName = "public:messages:conversation_\(conversationId.uuidString)"
        let channel = supabase.realtimeV2.channel(channelName)

        Task {
            print("🟡 [Realtime] Task started for channel:", channelName)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            print("🟡 [Realtime] Registering postgresChange listener")

            let changes = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "messages",
                filter: .eq("conversation_id", value: conversationId.uuidString)
            )

            print("🟡 [Realtime] Listener registered, now subscribing…")

            do {
                try await channel.subscribeWithError()
                print("✅ [Realtime] Channel subscribed SUCCESSFULLY:", channelName)
            } catch {
                print("🔴 [Realtime] Channel subscription FAILED:", error)
                await MainActor.run {
                    onMessage(.failure(error))
                }
                return
            }

            print("🟢 [Realtime] Waiting for INSERT events…")

            for await insert in changes {
                print("📥 [Realtime] INSERT event received")

                do {
                    let message = try insert.decodeRecord(
                        as: DBMessage.self,
                        decoder: decoder
                    )

                    print("✅ [Realtime] Decoded message id:", message.id)
                    print("   ↳ conversation_id:", message.conversationId)
                    print("   ↳ sender_id:", message.senderId)
                    print("   ↳ text:", message.text)

                    await MainActor.run {
                        print("🧵 [Realtime] Delivering message to UI")
                        onMessage(.success(message))
                    }
                } catch {
                    print("🔴 [Realtime] Failed to decode INSERT payload:", error)
                    await MainActor.run {
                        onMessage(.failure(error))
                    }
                }
            }

            print("⚠️ [Realtime] postgresChange stream ENDED")
        }

        return channel
    }

    /// Lightweight polling fallback for environments without realtime.
    func startPollingMessages(
        conversationId: UUID,
        lastTimestamp: Date?,
        interval: TimeInterval = 10,
        onBatch: @escaping (Result<[DBMessage], Error>) -> Void
    ) -> Task<Void, Never> {
        Task {
            var latestSeen = lastTimestamp

            while !Task.isCancelled {
                do {
                    let newMessages = try await fetchMessages(
                        conversationId: conversationId,
                        since: latestSeen
                    )

                    if let maxTimestamp = newMessages.map({ $0.timestamp }).max() {
                        latestSeen = maxTimestamp
                    }

                    if !newMessages.isEmpty {
                        await MainActor.run {
                            onBatch(.success(newMessages))
                        }
                    }
                } catch {
                    await MainActor.run {
                        onBatch(.failure(error))
                    }
                }

                // Sleep to avoid hammering the free-tier limits.
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

}
