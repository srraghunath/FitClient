//
//  Schedule.swift
//  FitClient
//
//  Created by admin6 on 11/11/25.
//

import Foundation

// MARK: - Weekday Model
enum Weekday: String, Codable, CaseIterable {
    case monday = "M"
    case tuesday = "T"
    case wednesday = "W"
    case thursday = "Th"
    case friday = "F"
    case saturday = "Sa"
    case sunday = "Su"
    
    var index: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
}

// MARK: - Schedule Item Models
struct ScheduleItem: Codable {
    let id: String
    let title: String
    let description: String
    let type: ScheduleItemType
    var isExpanded: Bool = false
    var selectedDays: [Weekday] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case type
        case isExpanded = "is_expanded"
        case selectedDays = "selected_days"
    }
    
    // Standard initializer
    init(id: String, title: String, description: String, type: ScheduleItemType, isExpanded: Bool = false, selectedDays: [Weekday] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.isExpanded = isExpanded
        self.selectedDays = selectedDays
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        type = try container.decode(ScheduleItemType.self, forKey: .type)
        isExpanded = try container.decodeIfPresent(Bool.self, forKey: .isExpanded) ?? false
        selectedDays = try container.decodeIfPresent([Weekday].self, forKey: .selectedDays) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(type, forKey: .type)
        try container.encode(isExpanded, forKey: .isExpanded)
        try container.encode(selectedDays, forKey: .selectedDays)
    }
}

enum ScheduleItemType: String, Codable {
    case collapsible  // Workout, Diet Plan
    case slider       // Sleep Schedule, Water Intake
    case textInput    // Cardio
}

// MARK: - Slider Item Model
struct SliderItem: Codable {
    let id: String
    let title: String
    let unit: String
    let minValue: Double
    let maxValue: Double
    var currentValue: Double
    let displayValue: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case unit
        case minValue = "min_value"
        case maxValue = "max_value"
        case currentValue = "current_value"
        case displayValue = "display_value"
    }
    
    mutating func updateValue(_ value: Double) {
        let clampedValue = max(minValue, min(maxValue, value))
        self.currentValue = clampedValue
    }
}

// MARK: - Day Schedule Model
struct DaySchedule: Codable {
    let day: Weekday
    var isActive: Bool
    var scheduleItems: [ScheduleItem]
    
    enum CodingKeys: String, CodingKey {
        case day
        case isActive = "is_active"
        case scheduleItems = "schedule_items"
    }
    
    // Standard initializer
    init(day: Weekday, isActive: Bool, scheduleItems: [ScheduleItem] = []) {
        self.day = day
        self.isActive = isActive
        self.scheduleItems = scheduleItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dayString = try container.decode(String.self, forKey: .day)
        day = Weekday(rawValue: dayString) ?? .monday
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        scheduleItems = try container.decodeIfPresent([ScheduleItem].self, forKey: .scheduleItems) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day.rawValue, forKey: .day)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(scheduleItems, forKey: .scheduleItems)
    }
}

// MARK: - Complete Schedule Model
struct ClientSchedule: Codable {
    let clientId: String
    var weekSchedule: [DaySchedule]
    var sliderItems: [SliderItem]
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case weekSchedule = "week_schedule"
        case sliderItems = "slider_items"
    }
    
    // Standard initializer
    init(clientId: String, weekSchedule: [DaySchedule], sliderItems: [SliderItem] = []) {
        self.clientId = clientId
        self.weekSchedule = weekSchedule
        self.sliderItems = sliderItems
    }
    
    mutating func toggleDay(_ weekday: Weekday) {
        if let index = weekSchedule.firstIndex(where: { $0.day == weekday }) {
            weekSchedule[index].isActive.toggle()
        }
    }
    
    func isActiveDays(on weekday: Weekday) -> Bool {
        return weekSchedule.first(where: { $0.day == weekday })?.isActive ?? false
    }
}
