//
//  PhotoModeManager.swift
//  kawaii
//
//  Created by Los Mayers on 6/25/25.
//

import Foundation
import Combine

class PhotoModeManager: ObservableObject {
    @Published var currentMode: PhotoMode = .mixed
    
    private let userDefaults = UserDefaults.standard
    private let photoModeKey = "selectedPhotoMode"
    
    init() {
        loadSavedMode()
    }
    
    func cycleToNextMode() {
        let currentIndex = PhotoMode.allCases.firstIndex(of: currentMode) ?? 0
        let nextIndex = (currentIndex + 1) % PhotoMode.allCases.count
        currentMode = PhotoMode.allCases[nextIndex]
        saveCurrentMode()
        print("Photo mode switched to: \(currentMode.description)")
    }
    
    private func saveCurrentMode() {
        switch currentMode {
        case .mixed:
            userDefaults.set("mixed", forKey: photoModeKey)
        case .faceOnly:
            userDefaults.set("faceOnly", forKey: photoModeKey)
        case .anyPhoto:
            userDefaults.set("anyPhoto", forKey: photoModeKey)
        }
    }
    
    private func loadSavedMode() {
        let savedMode = userDefaults.string(forKey: photoModeKey) ?? "mixed"
        switch savedMode {
        case "faceOnly":
            currentMode = .faceOnly
        case "anyPhoto":
            currentMode = .anyPhoto
        default:
            currentMode = .mixed
        }
    }
}
