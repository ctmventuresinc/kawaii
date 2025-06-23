//
//  DateSelectionViewModel.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import Foundation

@MainActor
class DateSelectionViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var formattedTravelDate: String = ""
    
    private let dateNavigator = DateNavigationUseCase.shared
    private let dateFormatter = DateFormattingService.shared
    
    init() {
        // Start with one month ago as default
        self.selectedDate = dateNavigator.oneMonthAgo()
        updateFormattedDate()
    }
    
    func navigateToOneMonthAgo() {
        selectedDate = dateNavigator.oneMonthAgo()
        updateFormattedDate()
    }
    
    func navigateToOneDayAgo() {
        selectedDate = dateNavigator.oneDayAgo(from: selectedDate)
        updateFormattedDate()
    }
    
    func navigateToOneWeekAgo() {
        selectedDate = dateNavigator.oneWeekAgo(from: selectedDate)
        updateFormattedDate()
    }
    
    func navigateToDate(_ date: Date) {
        selectedDate = dateNavigator.navigateToDate(date)
        updateFormattedDate()
    }
    
    func getCurrentDateRange() -> (start: Date, end: Date) {
        return dateNavigator.getCurrentDateRange(for: selectedDate)
    }
    
    private func updateFormattedDate() {
        formattedTravelDate = dateFormatter.formatTravelDate(selectedDate)
    }
    
    func getDebugDate() -> String {
        return dateFormatter.formatDebugDate(selectedDate)
    }
}
