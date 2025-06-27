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
        
        var total: Int { faceDetectionPercent + regularPhotoPercent + backgroundOnlyPercent }
        
        init(face: Int, regular: Int, background: Int) {
            assert(face + regular + background == 100, "Percentages must total 100")
            self.faceDetectionPercent = face
            self.regularPhotoPercent = regular
            self.backgroundOnlyPercent = background
        }
    }
    
    /// Current configuration - CHANGE PERCENTAGES HERE ONLY
    private let currentConfig = PhotoTypeConfig(
        face: 15,     // 15% face detection 
        regular: 65,  // 65% regular photos
        background: 20 // 20% background only
    )
    
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
        print("📊 PHOTO TYPE CONFIG: Face: \(currentConfig.faceDetectionPercent)%, Regular: \(currentConfig.regularPhotoPercent)%, Background: \(currentConfig.backgroundOnlyPercent)%")
    }
}

/// Processing type enum (moved here for clarity)
enum ProcessingType {
    case none           // Regular photo with background removal
    case faceDetection  // Face cropped with background removed  
    case backgroundOnly // Background removed, no face crop
}
