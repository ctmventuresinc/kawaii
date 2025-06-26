//
//  PhotoCacheManager.swift
//  kawaii
//
//  Created by Amp on 6/26/25.
//

import Foundation
import Photos
import UIKit

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
        let processedImage: UIImage? // Face-cropped or background-removed
    }
    
    private let poolSize = 8 // Keep 8 photos ready
    private let backgroundQueue = DispatchQueue(label: "photo.preprocessing", qos: .userInitiated)
    
    func getCachedPhotoInstantly(for date: Date, photoMode: PhotoMode) -> PreprocessedPhoto? {
        // Return immediately if we have a suitable photo
        guard let photo = getSuitablePhotoFromPool(for: photoMode) else {
            // Start background refill if pool is low
            if readyPhotoPool.count < 3 {
                Task { await refillPhotoPool(for: date) }
            }
            return nil
        }
        
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
            return readyPhotoPool.first { $0.hasFaces }
        case .anyPhoto:
            return readyPhotoPool.first
        case .mixed:
            let randomValue = Int.random(in: 1...100)
            if randomValue <= 30 {
                return readyPhotoPool.first { $0.hasFaces }
            } else {
                return readyPhotoPool.first
            }
        }
    }
    
    func prefillPhotosForDate(_ date: Date) {
        Task {
            await refillPhotoPool(for: date)
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
        
        // Fill pool to capacity
        let needed = poolSize - readyPhotoPool.count
        guard needed > 0 else {
            isPreprocessing = false
            return
        }
        
        await withTaskGroup(of: PreprocessedPhoto?.self) { group in
            for _ in 0..<min(needed, 5) { // Process max 5 at once
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
        
        isPreprocessing = false
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
    
    private func preprocessRandomPhoto(from fetchResult: PHFetchResult<PHAsset>) async -> PreprocessedPhoto? {
        let randomIndex = Int.random(in: 0..<fetchResult.count)
        let asset = fetchResult.object(at: randomIndex)
        
        // Load image
        guard let image = await loadImage(from: asset) else { return nil }
        
        // Detect faces
        let hasFaces = await detectFaces(in: image)
        let processedImage = hasFaces ? await cropFace(from: image) : nil
        
        return PreprocessedPhoto(
            asset: asset,
            image: image,
            hasFaces: hasFaces,
            processedImage: processedImage
        )
    }
    
    private func loadImage(from asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 400, height: 400),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    private func detectFaces(in image: UIImage) async -> Bool {
        // Simplified face detection - implement using Vision framework
        return await withCheckedContinuation { continuation in
            // Add your existing face detection logic here
            continuation.resume(returning: Bool.random()) // Placeholder
        }
    }
    
    private func cropFace(from image: UIImage) async -> UIImage? {
        // Add your existing face cropping logic here
        return image // Placeholder
    }
}
