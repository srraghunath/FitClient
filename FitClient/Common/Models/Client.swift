

import Foundation

struct Client: Codable {
    let id: String
    let name: String
    let email: String
    let profileImage: String
    let age: Int?
    let specialization: String?
    let level: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case profileImage = "profile_image"
        case age
        case specialization
        case level
    }
}

struct ClientsData: Codable {
    let clients: [Client]
}
