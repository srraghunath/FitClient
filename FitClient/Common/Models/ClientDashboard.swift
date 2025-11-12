//
//  ClientDashboard.swift
//  FitClient
//
//  Created by admin8 on 12/11/25.
//

import Foundation

struct ClientDashboardData: Codable {
    let dashboard: ClientDashboard
}

struct ClientDashboard: Codable {
    let userName: String
    let greeting: String
    let upcomingSession: UpcomingSession
    let todayWorkouts: [TodayWorkout]
    let todayDiet: [TodayMeal]
    let progressStats: ProgressStats
}

struct UpcomingSession: Codable {
    let title: String
    let time: String
    let trainer: String
}

struct TodayWorkout: Codable {
    let id: String
    let name: String
    let reps: String
    let imageUrl: String
}

struct TodayMeal: Codable {
    let id: String
    let mealType: String
    let name: String
    let calories: String
    let time: String
    let imageUrl: String
}

struct ProgressStats: Codable {
    let workoutsCompleted: Int
    let caloriesBurned: Int
    let activeMinutes: Int
}
