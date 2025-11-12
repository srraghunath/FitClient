import Foundation

struct ClientActivity: Codable {
    let id: String
    let type: String
    let category: String
    let timestamp: Date
    
    var daysAgo: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: timestamp, to: Date())
        return components.day ?? 0
    }
    
    var daysAgoText: String {
        let days = daysAgo
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else {
            return "\(days)d ago"
        }
    }
}

struct ClientProfile: Codable {
    let totalActiveDays: Int
    let consecutiveActiveDays: Int
    let recentActivities: [ClientActivity]
}

struct ClientProfileData: Codable {
    let profiles: [String: ClientProfile]  // Client ID as key
}