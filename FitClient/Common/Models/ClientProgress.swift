import Foundation

struct ClientActivityData: Codable {
    let clientId: String
    let monthlyData: [String: [DailyActivityItem]]

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case monthlyData = "monthly_data"
    }
}

struct DailyActivityItem: Codable {
    let date: String
    let workout: Bool
    let diet: Bool
    let sleep: Bool
    let waterIntake: Bool
    let cardio: Bool
    
    var totalCompleted: Int {
        var count = 0
        if workout { count += 1 }
        if diet { count += 1 }
        if sleep { count += 1 }
        if waterIntake { count += 1 }
        if cardio { count += 1 }
        return count
    }

    enum CodingKeys: String, CodingKey {
        case date, workout, diet, sleep, cardio
        case waterIntake = "water_intake"
    }
}
