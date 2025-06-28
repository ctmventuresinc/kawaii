//
//  PhotoCacheManager.swift
//  kawaii
//
//  Created by Amp on 6/26/25.
//

import Foundation
import Photos
import UIKit
import Vision

@MainActor
class PhotoCacheManager: ObservableObject {
    private var cachedFetchResult: PHFetchResult<PHAsset>?
    private var cachedDate: Date?
    private var readyPhotoPool: [PreprocessedPhoto] = []
    private var isPreprocessing = false
    
    // CENTRALIZED DECISION SERVICE - SINGLE SOURCE OF TRUTH
    private let photoTypeDecisionService = PhotoTypeDecisionService()
    
    // DUPLICATE PREVENTION
    private var usedAssetIds: Set<String> = []
    
    struct PreprocessedPhoto {
        let asset: PHAsset
        let image: UIImage
        let hasFaces: Bool
        let faceImage: UIImage? // Face-cropped image
        let backgroundRemovedImage: UIImage? // Background-removed image
        let processingType: ProcessingType
    }
    
    // ProcessingType moved to PhotoTypeDecisionService - import from there
    
    private let poolSize = 20 // Keep 20 photos ready - need more for aggressive face detection
    private let backgroundQueue = DispatchQueue(label: "photo.preprocessing", qos: .userInitiated)
    
    func getCachedPhotoInstantly(for date: Date, photoMode: PhotoMode) -> PreprocessedPhoto? {
        // STEP 1: BYPASS CACHE - Always return nil to force fallback path
        print("🔍 CACHE: BYPASSED - Always using fallback path")
        return nil
    }
    
    private func getSuitablePhotoFromPool(for mode: PhotoMode) -> PreprocessedPhoto? {
        switch mode {
        case .faceOnly:
            // Only face detection photos, fallback to any photo if none found
            return readyPhotoPool.first { $0.processingType == .faceDetection } ?? readyPhotoPool.first
        case .anyPhoto:
            // Regular photos preferred, fallback to any photo
            return readyPhotoPool.first { $0.processingType == .none } ?? readyPhotoPool.first
        case .mixed:
            // USE CENTRALIZED DECISION SERVICE - NO MORE SCATTERED LOGIC
            let requestedType = photoTypeDecisionService.getPhotoTypeForMixedMode()
            photoTypeDecisionService.logCurrentConfig()
            
            if let photo = readyPhotoPool.first(where: { $0.processingType == requestedType }) {
                return photo
            }
            
            // Fallback to any available photo if requested type not available
            return readyPhotoPool.first
        }
    }
    
    func prefillPhotosForDate(_ date: Date) {
        print("🔍 CACHE: Starting aggressive prefill for date: \(date)")
        
        // Check if date changed - clear cache if needed
        if let cachedDate = cachedDate, !Calendar.current.isDate(cachedDate, inSameDayAs: date) {
            print("🔍 CACHE: Date changed from \(cachedDate) to \(date) - clearing cache")
            clearCache()
        }
        
        Task {
            await refillPhotoPool(for: date)
        }
    }
    
    func clearCache() {
        readyPhotoPool.removeAll()
        cachedFetchResult = nil
        cachedDate = nil
        if FeatureFlags.shared.preventDuplicatePhotos {
            usedAssetIds.removeAll() // Reset duplicates on cache clear
            FeatureFlags.shared.clearUsedAssets() // Clear global tracking too
        }
        print("🔍 CACHE: Cache cleared - Pool now empty")
    }
    
    func ensureFacePhotosAvailable(for date: Date) async {
        // USE CENTRALIZED DECISION SERVICE - only search if config requires faces
        if photoTypeDecisionService.shouldDoAggressiveFaceSearch() {
            let currentFacePhotos = readyPhotoPool.filter { $0.processingType == .faceDetection }.count
            let minRequired = photoTypeDecisionService.getMinimumFacePhotosRequired()
            if currentFacePhotos == 0 {
                print("🔍 CACHE: No face photos available - forcing aggressive search")
                let fetchResult = await getCachedFetchResult(for: date)
                if fetchResult.count > 0 {
                    await aggressivelyFindFacePhotos(from: fetchResult, needed: minRequired)
                }
            }
        }
    }
    
    private func refillPhotoPool(for date: Date) async {
        guard !isPreprocessing else { return }
        isPreprocessing = true
        
        // Get or update cached fetch result
        let fetchResult = await getCachedFetchResult(for: date)
        guard fetchResult.count > 0 else {
            isPreprocessing = false
            return
        }
        
        // Check how many face photos we have
        let currentFacePhotos = await MainActor.run { 
            readyPhotoPool.filter { $0.processingType == .faceDetection }.count 
        }
        let currentPoolSize = await MainActor.run { readyPhotoPool.count }
        
        print("🔍 CACHE: Current pool - Total: \(currentPoolSize), Face photos: \(currentFacePhotos)")
        
        // USE CENTRALIZED DECISION SERVICE - only do aggressive face search if config requires it
        if photoTypeDecisionService.shouldDoAggressiveFaceSearch() {
            let minRequired = photoTypeDecisionService.getMinimumFacePhotosRequired()
            if currentFacePhotos < minRequired {
                print("🔍 CACHE: AGGRESSIVE FACE DETECTION - Need \(minRequired - currentFacePhotos) more face photos")
                await aggressivelyFindFacePhotos(from: fetchResult, needed: minRequired - currentFacePhotos)
            }
        }
        
        // Then fill rest of pool with mixed content
        let totalNeeded = poolSize - (await MainActor.run { readyPhotoPool.count })
        if totalNeeded > 0 {
            await fillRemainingPool(from: fetchResult, needed: totalNeeded)
        }
        
        isPreprocessing = false
    }
    
    private func aggressivelyFindFacePhotos(from fetchResult: PHFetchResult<PHAsset>, needed: Int) async {
        print("🔍 CACHE: Starting aggressive face search for \(needed) photos...")
        var found = 0
        var attempts = 0
        let maxTotalAttempts = min(50, fetchResult.count) // Try up to 50 photos like original
        
        while found < needed && attempts < maxTotalAttempts {
            let randomIndex = Int.random(in: 0..<fetchResult.count)
            let asset = fetchResult.object(at: randomIndex)
            attempts += 1
            
            // Skip screenshots
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                continue
            }
            
            print("🔍 CACHE: Face search attempt \(attempts)/\(maxTotalAttempts)")
            
            // Try to create face photo
            if let facePhoto = await preprocessPhotoForFaces(asset: asset) {
                await MainActor.run {
                    self.readyPhotoPool.append(facePhoto)
                }
                found += 1
                print("🔍 CACHE: ✅ Found face photo! (\(found)/\(needed))")
            }
        }
        
        print("🔍 CACHE: Aggressive face search complete - Found \(found) face photos in \(attempts) attempts")
    }
    
    private func fillRemainingPool(from fetchResult: PHFetchResult<PHAsset>, needed: Int) async {
        await withTaskGroup(of: PreprocessedPhoto?.self) { group in
            for _ in 0..<min(needed, 8) { // Process max 8 at once
                group.addTask {
                    await self.preprocessRandomPhoto(from: fetchResult)
                }
            }
            
            for await photo in group {
                if let photo = photo {
                    await MainActor.run {
                        // Final duplicate check before adding to pool (prevent race conditions)
                        let alreadyInPool = self.readyPhotoPool.contains { $0.asset.localIdentifier == photo.asset.localIdentifier }
                        if !alreadyInPool {
                            self.readyPhotoPool.append(photo)
                            print("🔍 CACHE: Added photo to pool - Total: \(self.readyPhotoPool.count)")
                        } else {
                            print("🔍 CACHE: ⚠️  Prevented duplicate from being added to pool")
                        }
                    }
                }
            }
        }
    }
    
    private func getCachedFetchResult(for date: Date) async -> PHFetchResult<PHAsset> {
        // Check if we need to refetch
        if let cachedDate = cachedDate, Calendar.current.isDate(cachedDate, inSameDayAs: date),
           let cached = cachedFetchResult {
            return cached
        }
        
        // Fresh fetch on background queue
        return await withCheckedContinuation { continuation in
            backgroundQueue.async {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                fetchOptions.predicate = NSPredicate(
                    format: "creationDate >= %@ AND creationDate < %@ AND NOT (mediaSubtypes & %d) != 0",
                    startOfDay as NSDate, endOfDay as NSDate, PHAssetMediaSubtype.photoScreenshot.rawValue
                )
                fetchOptions.fetchLimit = 100
                
                let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                Task { @MainActor in
                    self.cachedFetchResult = result
                    self.cachedDate = date
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func preprocessPhotoForFaces(asset: PHAsset) async -> PreprocessedPhoto? {
        // Load image at face detection size
        guard let image = await loadImage(from: asset, isForFaceDetection: true) else { return nil }
        
        // Single face detection and crop call - just like original
        guard let faceImage = await cropFace(from: image) else { 
            print("🔍 CACHE: No faces found in aggressive search")
            return nil 
        }
        
        // Apply background removal to face image - MUST succeed
        guard let backgroundRemovedImage = await removeBackground(from: faceImage) else {
            print("🔍 CACHE: ❌ Background removal failed for face photo - rejecting")
            return nil
        }
        
        print("🔍 CACHE: ✅ Successfully created face photo with background removal")
        
        return PreprocessedPhoto(
            asset: asset,
            image: image,
            hasFaces: true,
            faceImage: faceImage,
            backgroundRemovedImage: backgroundRemovedImage,
            processingType: .faceDetection
        )
    }
    
    private func preprocessRandomPhoto(from fetchResult: PHFetchResult<PHAsset>) async -> PreprocessedPhoto? {
        // Try up to 10 times to find an unused photo (if duplicate prevention enabled)
        let maxAttempts = FeatureFlags.shared.preventDuplicatePhotos ? 10 : 1
        for _ in 0..<maxAttempts {
            let randomIndex = Int.random(in: 0..<fetchResult.count)
            let asset = fetchResult.object(at: randomIndex)
            
            // Skip if already used (check both local cache and global tracking)
            if FeatureFlags.shared.preventDuplicatePhotos {
                let locallyUsed = await MainActor.run { usedAssetIds.contains(asset.localIdentifier) }
                let globallyUsed = await MainActor.run { FeatureFlags.shared.isAssetUsed(asset.localIdentifier) }
                if locallyUsed || globallyUsed {
                    continue
                }
            }
            
            // USE CENTRALIZED DECISION SERVICE
            var processingType: ProcessingType = photoTypeDecisionService.getPhotoTypeForPreprocessing()
        
            // Load image with appropriate size
            let isForFaceDetection = processingType == .faceDetection
            guard let image = await loadImage(from: asset, isForFaceDetection: isForFaceDetection) else { continue }
        
            // Process based on type
            var hasFaces = false
            var faceImage: UIImage? = nil
            var backgroundRemovedImage: UIImage? = nil
            
            switch processingType {
            case .faceDetection:
                // Single face detection call like original - avoid double detection inconsistencies
                faceImage = await cropFace(from: image)
                if let faceImg = faceImage {
                    hasFaces = true
                    // Apply background removal to face image - MUST succeed
                    backgroundRemovedImage = await removeBackground(from: faceImg)
                    guard backgroundRemovedImage != nil else {
                        print("🔍 CACHE: ❌ Background removal failed for face image - trying next photo")
                        continue
                    }
                } else {
                    // No faces found, convert to regular photo
                    hasFaces = false
                    processingType = .none
                    backgroundRemovedImage = await removeBackground(from: image)
                    guard backgroundRemovedImage != nil else {
                        print("🔍 CACHE: ❌ Background removal failed for regular image - trying next photo")
                        continue
                    }
                }
            case .backgroundOnly:
                backgroundRemovedImage = await removeBackground(from: image)
                guard backgroundRemovedImage != nil else {
                    print("🔍 CACHE: ❌ Background removal failed for background-only image - trying next photo")
                    continue
                }
            case .none:
                // Even "regular" photos get background removal in original code
                backgroundRemovedImage = await removeBackground(from: image)
                guard backgroundRemovedImage != nil else {
                    print("🔍 CACHE: ❌ Background removal failed for regular image - trying next photo")
                    continue
                }
            }
            
            print("🔍 CACHE: Preprocessed photo - Type: \(processingType), HasFaces: \(hasFaces), FaceImage: \(faceImage != nil), BgRemoved: \(backgroundRemovedImage != nil)")
            
            return PreprocessedPhoto(
                asset: asset,
                image: image,
                hasFaces: hasFaces,
                faceImage: faceImage,
                backgroundRemovedImage: backgroundRemovedImage,
                processingType: processingType
            )
        }
        
        // If we get here, all attempts failed
        let attempts = FeatureFlags.shared.preventDuplicatePhotos ? "10" : "1"
        print("🔍 CACHE: Failed to find suitable unused photo after \(attempts) attempts")
        return nil
    }
    
    private func loadImage(from asset: PHAsset, isForFaceDetection: Bool = false) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            // Use original high-quality sizing
            let maxDisplaySize: CGFloat = isForFaceDetection ? 234 : 450
            let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    private func detectFaces(in image: UIImage) async -> Bool {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: false)
                return
            }
            
            let request = VNDetectFaceRectanglesRequest { request, error in
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: false)
                    return
                }
                
                let minFaceSize: CGFloat = 0.10
                let qualityFaces = observations.filter { face in
                    return face.boundingBox.width > minFaceSize && face.boundingBox.height > minFaceSize
                }
                
                continuation.resume(returning: !qualityFaces.isEmpty)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }
    
    private func cropFace(from image: UIImage) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: nil)
                return
            }
            
            let request = VNDetectFaceRectanglesRequest { request, error in
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let minFaceSize: CGFloat = 0.10
                let qualityFaces = observations.filter { face in
                    return face.boundingBox.width > minFaceSize && face.boundingBox.height > minFaceSize
                }
                
                guard let firstQualityFace = qualityFaces.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let croppedImage = self.cropFaceFromImage(image, faceObservation: firstQualityFace)
                continuation.resume(returning: croppedImage)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }
    
    private func cropFaceFromImage(_ image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        let boundingBox = faceObservation.boundingBox
        let faceRect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        
        let padding: CGFloat = 0.4
        let paddedRect = CGRect(
            x: max(0, faceRect.origin.x - faceRect.width * padding),
            y: max(0, faceRect.origin.y - faceRect.height * padding),
            width: min(imageSize.width, faceRect.width * (1 + 2 * padding)),
            height: min(imageSize.height, faceRect.height * (1 + 2 * padding))
        )
        
        guard let croppedCGImage = cgImage.cropping(to: paddedRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func removeBackground(from image: UIImage) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let backgroundRemover = BackgroundRemover()
            backgroundRemover.removeBackground(of: image) { processedImage in
                continuation.resume(returning: processedImage)
            }
        }
    }
}
