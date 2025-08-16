//
//  PhotoItemsManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import Foundation

class FeatureFlags {
    static let shared = FeatureFlags()
    private init() {}
    
    // FEATURE FLAGS - EDIT THESE
	
	// developer/testing
	var testing: Bool = true
	
	//app store
	var appStoreReviewMode: Bool = false
	
	// PUSH NOTIFICATION CONTROLS
	var requireNotificationForRewind: Bool = false        // When false, rewind works without notifications
	var showAppLaunchNotificationPrompt: Bool = true     // When false, no notification prompt on app launch
	
	//regylar
    var preventDuplicatePhotos: Bool = true
    var enablePhotoSystemLogging: Bool = true
    var enableNewAnimations: Bool = false
    var enableBetaUI: Bool = false
    
    
    // DUPLICATE TRACKING - used by preventDuplicatePhotos
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
    
    func logAllFlags() {
        print("🚩 FEATURE FLAGS:")
        print("🚩 testing: \(testing)")
        print("🚩 appStoreReviewMode: \(appStoreReviewMode)")
        print("🚩 requireNotificationForRewind: \(requireNotificationForRewind)")
        print("🚩 showAppLaunchNotificationPrompt: \(showAppLaunchNotificationPrompt)")
        print("🚩 preventDuplicatePhotos: \(preventDuplicatePhotos)")
        print("🚩 enablePhotoSystemLogging: \(enablePhotoSystemLogging)")
        print("🚩 enableNewAnimations: \(enableNewAnimations)")
        print("🚩 enableBetaUI: \(enableBetaUI)")
    }
}
