//
//  PhotoTypeDecisionService.swift
//  kawaii
//
//  Created by Amp on 6/27/25.
//

import Foundation

/// Single source of truth for all photo type decisions
/// This service owns ALL percentage logic and photo type selection
class PhotoTypeDecisionService {
    
    // MARK: - Configuration (ONLY PLACE TO CHANGE PERCENTAGES)
    
    /// Current photo type percentages - SINGLE SOURCE OF TRUTH
    struct PhotoTypeConfig {
        let faceDetectionPercent: Int
        let regularPhotoPercent: Int  
        let backgroundOnlyPercent: Int
        let name: String
        
        var total: Int { faceDetectionPercent + regularPhotoPercent + backgroundOnlyPercent }
        
        init(name: String, face: Int, regular: Int, background: Int) {
            assert(face + regular + background == 100, "Percentages must total 100")
            self.name = name
            self.faceDetectionPercent = face
            self.regularPhotoPercent = regular
            self.backgroundOnlyPercent = background
        }
    }
    
    /// Available preset configurations
    enum PresetConfig {
        case optionF // "Your Target Mix" - 30/55/15 (2-3 face, 4-5 regular, 1 background)
        case optionG // "Conservative Face" - 25/60/15 (2 face, 5 regular, 1 background)  
        case optionH // "Balanced Target" - 35/50/15 (3 face, 4 regular, 1 background)
        case optionI // "More Background Variety" - 30/50/20 (2-3 face, 4 regular, 1-2 background)
        
        var config: PhotoTypeConfig {
            switch self {
            case .optionF:
                return PhotoTypeConfig(name: "Option F - Your Target Mix", face: 30, regular: 55, background: 15)
            case .optionG:
                return PhotoTypeConfig(name: "Option G - Conservative Face", face: 25, regular: 60, background: 15)
            case .optionH:
                return PhotoTypeConfig(name: "Option H - Balanced Target", face: 35, regular: 50, background: 15)
            case .optionI:
                return PhotoTypeConfig(name: "Option I - More Background Variety", face: 25, regular: 55, background: 20)
            }
        }
    }
    
    /// CHANGE THIS TO EXPERIMENT WITH DIFFERENT CONFIGURATIONS
    private let selectedPreset: PresetConfig = .optionI
    
    /// Current configuration - automatically uses selected preset
    private var currentConfig: PhotoTypeConfig {
        return selectedPreset.config
    }
    
    // MARK: - Public Interface
    
    /// Get the photo type that should be selected for mixed mode
    /// This is the ONLY method that decides photo types
    func getPhotoTypeForMixedMode() -> ProcessingType {
        let randomValue = Int.random(in: 1...100)
        
        if randomValue <= currentConfig.faceDetectionPercent {
            return .faceDetection
        } else if randomValue <= currentConfig.faceDetectionPercent + currentConfig.regularPhotoPercent {
            return .none
        } else {
            return .backgroundOnly
        }
    }
    
    /// Get the photo type for preprocessing pool generation
    func getPhotoTypeForPreprocessing() -> ProcessingType {
        return getPhotoTypeForMixedMode() // Same logic, centralized
    }
    
    /// Should we do aggressive face photo searching?
    /// Returns false if face percentage is 0
    func shouldDoAggressiveFaceSearch() -> Bool {
        return currentConfig.faceDetectionPercent > 0
    }
    
    /// Should we trigger aggressive face search for a cache miss?
    /// Returns false if face percentage is 0
    func shouldTriggerAggressiveSearchOnCacheMiss() -> Bool {
        return currentConfig.faceDetectionPercent > 0
    }
    
    /// Get minimum face photos to maintain in pool
    /// Returns 0 if face percentage is 0
    func getMinimumFacePhotosRequired() -> Int {
        return currentConfig.faceDetectionPercent > 0 ? 6 : 0
    }
    
    /// Get current configuration for debugging
    func getCurrentConfig() -> PhotoTypeConfig {
        return currentConfig
    }
    
    /// Log current configuration
    func logCurrentConfig() {
        print("📊 PHOTO TYPE CONFIG: \(currentConfig.name)")
        print("📊 Face: \(currentConfig.faceDetectionPercent)%, Regular: \(currentConfig.regularPhotoPercent)%, Background: \(currentConfig.backgroundOnlyPercent)%")
    }
}

/// Processing type enum (moved here for clarity)
enum ProcessingType {
    case none           // Regular photo with background removal
    case faceDetection  // Face cropped with background removed  
    case backgroundOnly // Background removed, no face crop
}
