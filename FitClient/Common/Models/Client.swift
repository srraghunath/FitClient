

import Foundation

struct Client: Codable {
    let id: UUID
    let user_id: UUID
    let trainer_id: UUID?
    let full_name: String
    let age: Int?
    let gender: String?
    let goal: String?
    let profileImageURL: String?
    let created_at: Date

    // MARK: - Computed convenience
    var name: String { full_name }
    var profileImage: String { profileImageURL ?? "" }
    var level: String { profileSummary }
    var profileSummary: String {
        var parts: [String] = []
        if let gender, !gender.isEmpty {
            parts.append(gender)
        }
        if let age {
            parts.append("Age \(age)")
        }
        return parts.isEmpty ? "Client" : parts.joined(separator: " • ")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case trainer_id
        case full_name
        case age
        case gender
        case goal
        case created_at
        case profileImageURL = "profile_image_url"
        case profileImageLegacy = "profile_image"
    }

    init(
        id: UUID,
        user_id: UUID,
        trainer_id: UUID?,
        full_name: String,
        age: Int?,
        gender: String?,
        goal: String?,
        profileImageURL: String? = nil,
        created_at: Date = Date()
    ) {
        self.id = id
        self.user_id = user_id
        self.trainer_id = trainer_id
        self.full_name = full_name
        self.age = age
        self.gender = gender
        self.goal = goal
        self.profileImageURL = profileImageURL
        self.created_at = created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        user_id = try container.decode(UUID.self, forKey: .user_id)
        trainer_id = try container.decodeIfPresent(UUID.self, forKey: .trainer_id)
        full_name = try container.decode(String.self, forKey: .full_name)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        goal = try container.decodeIfPresent(String.self, forKey: .goal)
        created_at = try container.decodeIfPresent(Date.self, forKey: .created_at) ?? Date()
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
            ?? container.decodeIfPresent(String.self, forKey: .profileImageLegacy)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user_id, forKey: .user_id)
        try container.encodeIfPresent(trainer_id, forKey: .trainer_id)
        try container.encode(full_name, forKey: .full_name)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encode(created_at, forKey: .created_at)
    }
}

struct ClientsData: Codable {
    let clients: [Client]
}
