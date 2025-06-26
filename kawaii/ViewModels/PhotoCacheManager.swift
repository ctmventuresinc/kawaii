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
    
    struct PreprocessedPhoto {
        let asset: PHAsset
        let image: UIImage
        let hasFaces: Bool
        let faceImage: UIImage? // Face-cropped image
        let backgroundRemovedImage: UIImage? // Background-removed image
        let processingType: ProcessingType
    }
    
    enum ProcessingType {
        case none           // 60% - Regular photo
        case faceDetection  // 30% - Face cropped with background removed
        case backgroundOnly // 10% - Background removed, no face crop
    }
    
    private let poolSize = 20 // Keep 20 photos ready - need more for aggressive face detection
    private let minFacePhotos = 6 // Always maintain at least 6 face photos in pool
    private let backgroundQueue = DispatchQueue(label: "photo.preprocessing", qos: .userInitiated)
    
    func getCachedPhotoInstantly(for date: Date, photoMode: PhotoMode) -> PreprocessedPhoto? {
        print("🔍 CACHE: Looking for photo - Mode: \(photoMode), Pool size: \(readyPhotoPool.count)")
        print("🔍 CACHE: Pool types: \(readyPhotoPool.map { $0.processingType })")
        
        // Return immediately if we have a suitable photo
        guard let photo = getSuitablePhotoFromPool(for: photoMode) else {
            print("🔍 CACHE: No suitable photo found in pool")
            // Start background refill if pool is low
            if readyPhotoPool.count < 3 {
                Task { await refillPhotoPool(for: date) }
            }
            return nil
        }
        
        print("🔍 CACHE: Found suitable photo - Type: \(photo.processingType), HasFaces: \(photo.hasFaces)")
        
        // Remove from pool and start refill
        if let index = readyPhotoPool.firstIndex(where: { $0.asset.localIdentifier == photo.asset.localIdentifier }) {
            readyPhotoPool.remove(at: index)
        }
        
        // Async refill
        Task { await refillPhotoPool(for: date) }
        
        return photo
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
            let randomValue = Int.random(in: 1...100)
            if randomValue <= 30 {
                // 30% - Face detection photos (cropped faces with background removed)
                if let facePhoto = readyPhotoPool.first(where: { $0.processingType == .faceDetection }) {
                    return facePhoto
                }
                // If no face photos available, trigger aggressive search and return nil to force fallback
                print("🔍 CACHE: No face photos in pool for 30% request - needs aggressive refill")
                return nil
            } else if randomValue <= 90 {
                // 60% - Regular random photos (full photos, no processing)
                return readyPhotoPool.first { $0.processingType == .none } ?? readyPhotoPool.first
            } else {
                // 10% - Background removed but no face crop
                return readyPhotoPool.first { $0.processingType == .backgroundOnly } ?? readyPhotoPool.first
            }
        }
    }
    
    func prefillPhotosForDate(_ date: Date) {
        print("🔍 CACHE: Starting aggressive prefill for date: \(date)")
        Task {
            await refillPhotoPool(for: date)
        }
    }
    
    func ensureFacePhotosAvailable(for date: Date) async {
        // Force aggressive face detection if pool is empty or has no faces
        let currentFacePhotos = readyPhotoPool.filter { $0.processingType == .faceDetection }.count
        if currentFacePhotos == 0 {
            print("🔍 CACHE: No face photos available - forcing aggressive search")
            let fetchResult = await getCachedFetchResult(for: date)
            if fetchResult.count > 0 {
                await aggressivelyFindFacePhotos(from: fetchResult, needed: minFacePhotos)
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
        
        // If we don't have enough face photos, aggressively find them first
        if currentFacePhotos < minFacePhotos {
            print("🔍 CACHE: AGGRESSIVE FACE DETECTION - Need \(minFacePhotos - currentFacePhotos) more face photos")
            await aggressivelyFindFacePhotos(from: fetchResult, needed: minFacePhotos - currentFacePhotos)
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
                        self.readyPhotoPool.append(photo)
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
        
        // Try to detect and crop faces
        let hasFaces = await detectFaces(in: image)
        guard hasFaces else { return nil } // Only return if we found faces
        
        guard let faceImage = await cropFace(from: image) else { return nil }
        
        // Apply background removal to face image
        let backgroundRemovedImage = await removeBackground(from: faceImage)
        
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
        let randomIndex = Int.random(in: 0..<fetchResult.count)
        let asset = fetchResult.object(at: randomIndex)
        
        // Decide processing type based on mixed mode percentages
        let randomValue = Int.random(in: 1...100)
        var processingType: ProcessingType
        if randomValue <= 30 {
            processingType = .faceDetection
        } else if randomValue <= 90 {
            processingType = .none
        } else {
            processingType = .backgroundOnly
        }
        
        // Load image with appropriate size
        let isForFaceDetection = processingType == .faceDetection
        guard let image = await loadImage(from: asset, isForFaceDetection: isForFaceDetection) else { return nil }
        
        // Process based on type
        var hasFaces = false
        var faceImage: UIImage? = nil
        var backgroundRemovedImage: UIImage? = nil
        
        switch processingType {
        case .faceDetection:
            hasFaces = await detectFaces(in: image)
            if hasFaces {
                faceImage = await cropFace(from: image)
                // Apply background removal to face image
                if let faceImg = faceImage {
                    backgroundRemovedImage = await removeBackground(from: faceImg)
                }
            } else {
                // No faces found, convert to regular photo
                processingType = .none
                backgroundRemovedImage = await removeBackground(from: image)
            }
        case .backgroundOnly:
            backgroundRemovedImage = await removeBackground(from: image)
        case .none:
            // Even "regular" photos get background removal in original code
            backgroundRemovedImage = await removeBackground(from: image)
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
