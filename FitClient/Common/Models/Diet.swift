//
//  Diet.swift
//  FitClient
//

import Foundation

struct Diet: Codable {
    let id: String
    let name: String
    let grams: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let calories: Int
    let imageUrl: String
    let mealType: MealType
    let dietType: DietType
    var quantity: Int
    var isSelected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case grams
        case protein
        case carbs
        case fat
        case calories
        case imageUrl = "image_url"
        case mealType = "meal_type"
        case dietType = "diet_type"
        case quantity
        case isSelected = "is_selected"
    }
}

enum MealType: String, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
}

enum DietType: String, Codable, CaseIterable {
    case veg = "veg"
    case nonVeg = "non_veg"
    case vegan = "vegan"
    
    var displayName: String {
        switch self {
        case .veg: return "Veg"
        case .nonVeg: return "Non-Veg"
        case .vegan: return "Vegan"
        }
    }
}

struct DietsData: Codable {
    let diets: [Diet]
}
