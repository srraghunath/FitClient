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
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageUrl = "image_url"
        case category
        case isSelected = "is_selected"
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
