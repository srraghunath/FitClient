//
//  Workout.swift
//  FitClient
//

import Foundation

struct Workout: Codable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String
    let category: WorkoutCategory
    var isSelected: Bool
    var targetReps: Int? = nil
    var targetWeight: Double? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageUrl = "image_url"
        case category
        case isSelected = "is_selected"
        case targetReps = "target_reps"
        case targetWeight = "target_weight"
    }
}

enum WorkoutCategory: String, Codable {
    case lowerBody = "lower_body"
    case upperBody = "upper_body"
    case fullBody = "full_body"
}

struct WorkoutsData: Codable {
    let workouts: [Workout]
}

extension Workout {
    var targetSummary: String? {
        switch (targetReps, targetWeight) {
        case let (reps?, weight?):
            return "Target: \(reps) reps @ \(weight.cleanString) kg"
        case let (reps?, nil):
            return "Target: \(reps) reps"
        case let (nil, weight?):
            return "Target: \(weight.cleanString) kg"
        default:
            return nil
        }
    }
}

private extension Double {
    var cleanString: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
