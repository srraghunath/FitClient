import Foundation
import UIKit

// MARK: - Settings Menu Models

struct SettingsMenuData: Codable {
    let clientSettings: [SettingsMenuItem]
    let trainerSettings: [SettingsMenuItem]
}

struct SettingsMenuItem: Codable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let iconBackgroundColor: String
    var isProfileItem: Bool?
    
    var iconBgColor: UIColor {
        return UIColor(hex: iconBackgroundColor) ?? .clear
    }
}

// MARK: - Signup Options Models

struct SignupOptionsData: Codable {
    let genderOptions: [String]
    let goalOptions: [String]
}

// MARK: - Chat Responses Models

struct ChatResponsesData: Codable {
    let trainerResponses: [String]
    let clientResponses: [String]
}

// MARK: - UI Labels Models

struct UILabelsData: Codable {
    let weekdays: WeekdaysData
    let months: MonthsData
    let dayTracker: DayTrackerData
}

struct WeekdaysData: Codable {
    let short: [String]
    let full: [String]
}

struct MonthsData: Codable {
    let short: [String]
    let full: [String]
}

struct DayTrackerData: Codable {
    let items: [DayTrackerItemData]
}

struct DayTrackerItemData: Codable {
    let id: String
    let title: String
    let icon: String
}

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
