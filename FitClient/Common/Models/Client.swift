

import Foundation

struct Client: Codable {
    let id: UUID
    let user_id: UUID
    let trainer_id: UUID?
    let full_name: String
    let age: Int?
    let gender: String?
    let goal: String?
    let created_at: Date
    
    // These are not in the database, but are used in the UI
    var name: String { full_name }
    var profileImage: String { "" } // Placeholder for profile image
    var level: String { goal ?? "N/A" }
}

struct ClientsData: Codable {
    let clients: [Client]
}
