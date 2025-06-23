//
//  DateFormattingService.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import Foundation

class DateFormattingService {
    static let shared = DateFormattingService()
    
    private init() {}
    
    func formatTravelDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    func formatDebugDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    func endOfDay(for date: Date) -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(for: date)) ?? date
    }
}
