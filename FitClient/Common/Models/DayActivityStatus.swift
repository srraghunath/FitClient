//
//  DayActivityStatus.swift
//  FitClient
//
//  Created by Copilot on 11/14/25.
//

import Foundation

// Matches Resources/Data/clientActivityData.json
struct DayActivityCompletion: Codable {
    let date: String // yyyy-MM-dd
    let workout: Bool
    let diet: Bool
    let sleep: Bool
    let waterIntake: Bool
    let cardio: Bool
}

struct ClientMonthlyActivityData: Codable {
    let clientId: String
    let monthlyData: [String: [DayActivityCompletion]] // key: yyyy-MM
}
