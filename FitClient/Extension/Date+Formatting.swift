//
//  Date+Formatting.swift
//  FitClient
//
//  Created by Admin on 13/11/25.
//

import Foundation

extension Date {
    /// Formats date as "EEE , dd MMM yyyy" (e.g., "Wed , 29 Oct 2025")
    var dashboardFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE , dd MMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Converts date to "yyyy-MM-dd" string for JSON lookup
    var jsonKeyFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// Gets the day of week (e.g., "Monday", "Tuesday")
    var dayOfWeekFull: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Gets the short day of week (e.g., "Mon", "Tue")
    var dayOfWeekShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// Checks if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is in the past
    var isPast: Bool {
        self < Date()
    }
    
    /// Checks if date is in the future
    var isFuture: Bool {
        self > Date()
    }
    
    /// Checks if date is within last 90 days
    var isWithinLast90Days: Bool {
        let calendar = Calendar.current
        let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        return self >= ninetyDaysAgo && self <= Date()
    }
}
