//
//  DateNavigationUseCase.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import Foundation

enum DateMode {
    case daily        // Original mode - shows today, yesterday, etc.
    case weekend      // Weekend mode - shows last Fri-Sun
}

class DateNavigationUseCase {
    static let shared = DateNavigationUseCase()
    
    private init() {}
    
    func oneMonthAgo(from date: Date = Date()) -> Date {
        return Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
    }
    
    func oneDayAgo(from date: Date) -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    }
    
    func oneWeekAgo(from date: Date) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
    }
    
    func navigateToDate(_ targetDate: Date) -> Date {
        return targetDate
    }
    
    func lastWeekend(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        
        // Find the most recent Friday
        var searchDate = date
        while calendar.component(.weekday, from: searchDate) != 6 { // 6 = Friday
            searchDate = calendar.date(byAdding: .day, value: -1, to: searchDate) ?? searchDate
        }
        
        return searchDate
    }
    
    func previousWeekend(from currentWeekendFriday: Date) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekendFriday) ?? currentWeekendFriday
    }
    
    func getCurrentDateRange(for selectedDate: Date) -> (start: Date, end: Date) {
        let dateService = DateFormattingService.shared
        let startOfDay = dateService.startOfDay(for: selectedDate)
        let endOfDay = dateService.endOfDay(for: selectedDate)
        return (start: startOfDay, end: endOfDay)
    }
    
    func getWeekendDateRange(for fridayDate: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let dateService = DateFormattingService.shared
        
        let friday = dateService.startOfDay(for: fridayDate)
        let sunday = calendar.date(byAdding: .day, value: 2, to: friday) ?? friday
        let endOfSunday = dateService.endOfDay(for: sunday)
        
        return (start: friday, end: endOfSunday)
    }
}
