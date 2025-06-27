//
//  FeatureFlags.swift
//  kawaii
//
//  Created by Amp on 6/27/25.
//

import Foundation

/// Centralized feature flag management
/// Use this to control experimental or optional features across the app
class FeatureFlags {
    
    // MARK: - Singleton
    static let shared = FeatureFlags()
    private init() {}
    
    // MARK: - Shared Duplicate Tracking
    /// Global set of used asset IDs across all photo creation systems
    private var globalUsedAssetIds: Set<String> = []
    
    func markAssetAsUsed(_ assetId: String) {
        if preventDuplicatePhotos {
            globalUsedAssetIds.insert(assetId)
        }
    }
    
    func isAssetUsed(_ assetId: String) -> Bool {
        return preventDuplicatePhotos && globalUsedAssetIds.contains(assetId)
    }
    
    func clearUsedAssets() {
        globalUsedAssetIds.removeAll()
    }
    
    func getUsedAssetCount() -> Int {
        return globalUsedAssetIds.count
    }
    
    // MARK: - Photo System Features
    
    /// Prevents duplicate photos from appearing until cache is cleared
    /// Set to false if performance becomes an issue or duplicates are acceptable
    var preventDuplicatePhotos: Bool = true
    
    /// Enable verbose logging for photo system debugging
    var enablePhotoSystemLogging: Bool = true
    
    // MARK: - Future Feature Flags
    // Add new feature flags here as needed
    
    /// Example: Enable new animation system
    var enableNewAnimations: Bool = false
    
    /// Example: Enable beta UI components
    var enableBetaUI: Bool = false
    
    // MARK: - Utility Methods
    
    /// Print all current feature flag states for debugging
    func logAllFlags() {
        print("🚩 FEATURE FLAGS:")
        print("🚩 preventDuplicatePhotos: \(preventDuplicatePhotos)")
        print("🚩 enablePhotoSystemLogging: \(enablePhotoSystemLogging)")
        print("🚩 enableNewAnimations: \(enableNewAnimations)")
        print("🚩 enableBetaUI: \(enableBetaUI)")
    }
}
