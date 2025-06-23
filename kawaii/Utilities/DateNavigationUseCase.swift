//
//  DateNavigationUseCase.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import Foundation

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
    
    func getCurrentDateRange(for selectedDate: Date) -> (start: Date, end: Date) {
        let dateService = DateFormattingService.shared
        let startOfDay = dateService.startOfDay(for: selectedDate)
        let endOfDay = dateService.endOfDay(for: selectedDate)
        return (start: startOfDay, end: endOfDay)
    }
}
