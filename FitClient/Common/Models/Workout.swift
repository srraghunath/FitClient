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
    var targetSets: Int? = nil
    var targetReps: Int? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageUrl = "image_url"
        case category
        case isSelected = "is_selected"
        case targetSets = "target_sets"
        case targetReps = "target_reps"
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
        switch (targetSets, targetReps) {
        case let (sets?, reps?):
            return "Target: \(sets) sets x \(reps) reps"
        case let (sets?, nil):
            return "Target: \(sets) sets"
        case let (nil, reps?):
            return "Target: \(reps) reps"
        default:
            return nil
        }
    }
}

struct WorkoutTargetPreset: Codable {
    let workoutId: String
    let defaultSets: Int?
    let defaultReps: Int?
    
    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case defaultSets = "default_sets"
        case defaultReps = "default_reps"
    }
}

struct WorkoutTargetPresetsData: Codable {
    let targets: [WorkoutTargetPreset]
}
