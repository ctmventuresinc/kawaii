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
    @Published var currentMode: DateMode
    
    private let dateNavigator = DateNavigationUseCase.shared
    private let dateFormatter = DateFormattingService.shared
    
    init() {
        // Initialize with default weekend mode
		let mode: DateMode = .daily // SWITCH THIS TO .daily for old behavior
        self.currentMode = mode
        
        // Set initial date based on mode
        switch mode {
        case .daily:
            self.selectedDate = dateNavigator.oneMonthAgo()
        case .weekend:
            self.selectedDate = dateNavigator.lastWeekend()
        }
        updateFormattedDate()
    }
    
    func navigateToOneMonthAgo() {
        selectedDate = dateNavigator.oneMonthAgo()
        updateFormattedDate()
    }
    
    func navigateToOneDayAgo() {
        switch currentMode {
        case .daily:
            selectedDate = dateNavigator.oneDayAgo(from: selectedDate)
        case .weekend:
            selectedDate = dateNavigator.previousWeekend(from: selectedDate)
        }
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
        switch currentMode {
        case .daily:
            return dateNavigator.getCurrentDateRange(for: selectedDate)
        case .weekend:
            return dateNavigator.getWeekendDateRange(for: selectedDate)
        }
    }
    
    private func updateFormattedDate() {
        formattedTravelDate = dateFormatter.formatTravelDate(selectedDate)
    }
    
    func getDebugDate() -> String {
        return dateFormatter.formatDebugDate(selectedDate)
    }
}
