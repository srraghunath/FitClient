

import Foundation

struct Session: Codable {
    let id: String
    let clientId: String
    let clientName: String
    let clientProfileImage: String
    let startTime: String
    let endTime: String
    let date: String
    let isToday: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case clientName = "client_name"
        case clientProfileImage = "client_profile_image"
        case startTime = "start_time"
        case endTime = "end_time"
        case date
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
