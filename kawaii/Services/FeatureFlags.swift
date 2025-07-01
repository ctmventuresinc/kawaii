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
	var appStoreReviewMode: Bool = false
    var preventDuplicatePhotos: Bool = true
    var enablePhotoSystemLogging: Bool = true
    var enableNewAnimations: Bool = false
    var enableBetaUI: Bool = false
    var disablePushNotificationRequests: Bool = true
    
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
        print("🚩 appStoreReviewMode: \(appStoreReviewMode)")
        print("🚩 preventDuplicatePhotos: \(preventDuplicatePhotos)")
        print("🚩 enablePhotoSystemLogging: \(enablePhotoSystemLogging)")
        print("🚩 enableNewAnimations: \(enableNewAnimations)")
        print("🚩 enableBetaUI: \(enableBetaUI)")
        print("🚩 disablePushNotificationRequests: \(disablePushNotificationRequests)")
    }
}
