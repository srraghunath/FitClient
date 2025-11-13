import Foundation

// MARK: - Client Settings Models

struct ClientSettingsConfig: Codable {
    struct Notifications: Codable {
        let upcomingWorkouts: Bool
        let dietReminders: Bool
        let messages: Bool
        let goalProgress: Bool
        let email: Bool
        let push: Bool
    }

    struct Help: Codable {
        struct FAQ: Codable {
            let q: String
            let a: String
        }
        let contactEmail: String
        let contactPhone: String
        let faqs: [FAQ]
        let resources: [String]
    }

    let notifications: Notifications
    let help: Help
}

// MARK: - Trainer Settings Models

struct TrainerSettingsConfig: Codable {
    struct Notifications: Codable {
        let upcomingSessions: Bool
        let sessionChanges: Bool
        let newClientRequests: Bool
        let clientMessages: Bool
        let email: Bool
        let push: Bool
    }

    struct Help: Codable {
        struct FAQ: Codable {
            let q: String
            let a: String
        }
        let contactEmail: String
        let contactPhone: String
        let faqs: [FAQ]
        let resources: [String]
    }

    let notifications: Notifications
    let help: Help
}
