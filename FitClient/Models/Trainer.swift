//
//  Trainer.swift
//  FitClient
//
//  Created by admin8 on 04/11/25.
//

import Foundation

struct Trainer: Codable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let specialization: String
    let bio: String
    let profileImage: String
    let experienceYears: Int
    let certifications: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case specialization
        case bio
        case profileImage = "profile_image"
        case experienceYears = "experience_years"
        case certifications
    }
}

struct TrainerData: Codable {
    let trainer: Trainer
}
