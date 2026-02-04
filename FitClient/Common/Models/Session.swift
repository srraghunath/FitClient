

import Foundation

struct Session: Codable {
    let id: String
    let clientId: String
    let clientName: String
    let clientProfileImage: String
    let goal: String?
    let startTime: String?
    let endTime: String?
    let date: String
    let dayOfWeek: Int?
    let isToday: Bool
    
    var client: Client {
        return Client(
            id: UUID(uuidString: clientId) ?? UUID(),
            user_id: UUID(), // This needs to be fetched or passed in
            trainer_id: nil,
            full_name: clientName,
            age: nil,
            gender: nil,
            goal: "Fitness Goals",
            profileImageURL: clientProfileImage,
            created_at: Date()
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case clientName = "client_name"
        case clientProfileImage = "client_profile_image"
        case goal
        case startTime = "start_time"
        case endTime = "end_time"
        case date
        case dayOfWeek = "day_of_week"
        case isToday = "is_today"
    }
}

struct SessionsData: Codable {
    let todaySessions: [Session]
    let upcomingSessions: [Session]
    
    enum CodingKeys: String, CodingKey {
        case todaySessions = "today_sessions"
        case upcomingSessions = "upcoming_sessions"
    }
}
