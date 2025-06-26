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
            return readyPhotoPool.first { $0.processingType == .faceDetection }
        case .anyPhoto:
            return readyPhotoPool.first { $0.processingType == .none }
        case .mixed:
            let randomValue = Int.random(in: 1...100)
            if randomValue <= 30 {
                // 30% - Face detection photos (cropped faces with background removed)
                return readyPhotoPool.first { $0.processingType == .faceDetection }
            } else if randomValue <= 90 {
                // 60% - Regular random photos (full photos, no processing)
                return readyPhotoPool.first { $0.processingType == .none }
            } else {
                // 10% - Background removed but no face crop
                return readyPhotoPool.first { $0.processingType == .backgroundOnly }
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
        
        // Decide processing type based on mixed mode percentages
        let randomValue = Int.random(in: 1...100)
        let processingType: ProcessingType
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
            }
        case .backgroundOnly:
            backgroundRemovedImage = await removeBackground(from: image)
        case .none:
            // No processing needed
            break
        }
        
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
