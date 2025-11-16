import Foundation

enum UserRole: String, Codable {
    case client
    case trainer
}

struct User: Codable, Equatable {
    let id: String
    var email: String
    var passwordHash: String
    let role: UserRole
    var fullName: String
    var age: Int?
    var gender: String?
    var goal: String?
    var specialization: String?
}

struct UsersData: Codable {
    var users: [User]
}
