//
//  PhotoModeManager.swift
//  kawaii
//
//  Created by Los Mayers on 6/25/25.
//

import Foundation
import Combine

class PhotoModeManager: ObservableObject {
    @Published var currentMode: PhotoMode = .anyPhoto
    
    func cycleToNextMode() {
        let currentIndex = PhotoMode.allCases.firstIndex(of: currentMode) ?? 0
        let nextIndex = (currentIndex + 1) % PhotoMode.allCases.count
        currentMode = PhotoMode.allCases[nextIndex]
        print("Photo mode switched to: \(currentMode.description)")
    }
}
