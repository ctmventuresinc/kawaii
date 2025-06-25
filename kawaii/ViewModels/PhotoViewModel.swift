//
//  PhotoManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import Photos
import Vision

@MainActor
class PhotoViewModel: ObservableObject {
    @Published var currentMethod: PhotoRetrievalMethod = .facePhotosLastMonth
    private var usedAssetIds: Set<String> = []
    private var usedFaceIds: Set<String> = []
    let backgroundRemover = BackgroundRemover()
    
    func fetchRandomPhoto(completion: @escaping (UIImage?, PhotoRetrievalMethod) -> Void) {
        print("🔍 DEBUG: fetchRandomPhoto() started")
        fetchRandomPhotoWithFallback(preferredMethod: currentMethod, completion: completion)
    }
    
    private func fetchRandomPhotoWithFallback(preferredMethod: PhotoRetrievalMethod, completion: @escaping (UIImage?, PhotoRetrievalMethod) -> Void) {
        switch preferredMethod {
        case .recentPhotos:
            fetchRandomRecentPhoto { image in
                completion(image, .recentPhotos)
            }
        case .recentPhotosWithSVG:
            fetchRandomRecentPhoto { image in
                completion(image, .recentPhotosWithSVG)
            }
        case .facePhotos:
            fetchRandomFaceCrop(timeframe: .recent) { [weak self] image in
                if image != nil {
                    completion(image, .facePhotos)
                } else {
                    print("Face Crops failed, falling back to Recent Photos")
                    self?.fetchRandomPhotoWithFallback(preferredMethod: .recentPhotos, completion: completion)
                }
            }
        case .facePhotos30Days:
            fetchRandomFaceCrop(timeframe: .thirtyDays) { [weak self] image in
                if image != nil {
                    completion(image, .facePhotos30Days)
                } else {
                    print("Face Crops (30 Days) failed, falling back to Recent Photos")
                    self?.fetchRandomPhotoWithFallback(preferredMethod: .recentPhotos, completion: completion)
                }
            }
        case .facePhotosLastMonth:
            fetchRandomFaceCrop(timeframe: .lastMonth) { [weak self] image in
                if image != nil {
                    completion(image, .facePhotosLastMonth)
                } else {
                    print("Face Crops (Last Month) failed, falling back to Recent Photos")
                    self?.fetchRandomPhotoWithFallback(preferredMethod: .recentPhotos, completion: completion)
                }
            }
        }
    }
    
    enum TimeFrame {
        case recent, thirtyDays, lastMonth
    }
    
    private func fetchRandomRecentPhoto(completion: @escaping (UIImage?) -> Void) {
        // Move ALL Photos framework operations to background queue
        Task {
            print("🔍 DEBUG: fetchRandomRecentPhoto() started on background queue")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 50
            
            print("🔍 DEBUG: About to call PHAsset.fetchAssets")
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("🔍 DEBUG: PHAsset.fetchAssets completed, found \(fetchResult.count) assets")
        
        guard fetchResult.count > 0 else {
            completion(nil)
            return
        }
        
        var attempts = 0
        let maxAttempts = 20
        
        print("🔍 DEBUG: Starting while loop to find unused asset")
        while attempts < maxAttempts {
            let randomIndex = Int.random(in: 0..<fetchResult.count)
            let randomAsset = fetchResult.object(at: randomIndex)
            
            if !randomAsset.mediaSubtypes.contains(.photoScreenshot) && 
               !(await MainActor.run { self.usedAssetIds.contains(randomAsset.localIdentifier) }) {
                print("🔍 DEBUG: Found valid asset, calling loadPhoto")
                await self.loadPhoto(asset: randomAsset, completion: completion)
                await MainActor.run { self.usedAssetIds.insert(randomAsset.localIdentifier) }
                return
            }
            attempts += 1
        }
        print("🔍 DEBUG: No valid asset found after \(maxAttempts) attempts")
        completion(nil)
        }
    }
    
    private func fetchRandomFaceCrop(timeframe: TimeFrame, completion: @escaping (UIImage?) -> Void) {
        // Get photos from specified timeframe
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        switch timeframe {
        case .recent:
            fetchOptions.fetchLimit = 100
        case .thirtyDays:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", thirtyDaysAgo as NSDate)
            fetchOptions.fetchLimit = 200
        case .lastMonth:
            let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let lastMonthEnd = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", 
                                               lastMonthStart as NSDate, lastMonthEnd as NSDate)
            fetchOptions.fetchLimit = 300
        }
        
        let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard allAssets.count > 0 else {
            print("No photos found in specified timeframe")
            completion(nil) // Don't fallback - be strict about face crops
            return
        }
        
        // Try to find a photo with faces - be more persistent
        findPhotoWithFaces(from: allAssets, attempts: 0, maxAttempts: 50, completion: completion)
    }
    
    private func findPhotoWithFaces(from assets: PHFetchResult<PHAsset>, attempts: Int, maxAttempts: Int, completion: @escaping (UIImage?) -> Void) {
        guard attempts < maxAttempts, attempts < assets.count else {
            print("No faces found after \(attempts) attempts - STRICT MODE: No fallback")
            completion(nil) // Be strict - don't fallback to regular photos
            return
        }
        
        let randomIndex = Int.random(in: 0..<assets.count)
        let asset = assets.object(at: randomIndex)
        
        // Skip screenshots and already used assets
        if asset.mediaSubtypes.contains(.photoScreenshot) || usedAssetIds.contains(asset.localIdentifier) {
            findPhotoWithFaces(from: assets, attempts: attempts + 1, maxAttempts: maxAttempts, completion: completion)
            return
        }
        
        // Load the image and detect faces
        loadImageAndDetectFaces(asset: asset) { [weak self] faceImage in
            if let faceImage = faceImage {
                // Found a face! Mark asset as used and return the face crop
                self?.usedAssetIds.insert(asset.localIdentifier)
                completion(faceImage)
            } else {
                // No faces in this image, try next one
                self?.findPhotoWithFaces(from: assets, attempts: attempts + 1, maxAttempts: maxAttempts, completion: completion)
            }
        }
    }
    
    private func loadPhoto(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Load at display resolution (450px max) * 2 for retina * screen scale
        let maxDisplaySize: CGFloat = 450 // From your PhotoItem size range
        let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    private func loadImageAndDetectFaces(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Load at face crop display resolution (234px max) * 2 for retina * screen scale
        let maxFaceDisplaySize: CGFloat = 234 // From your face crop size range
        let targetPixelSize = maxFaceDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let fullImage = image else {
                completion(nil)
                return
            }
            
            // Detect faces using Vision framework
            self.detectAndCropFace(from: fullImage, completion: completion)
        }
    }
    
    private func detectAndCropFace(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation] else {
                // No faces detected
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Filter faces by minimum size (reject small background faces)
            let minFaceSize: CGFloat = 0.10 // Face must be at least 10% of image width/height
            let qualityFaces = observations.filter { face in
                return face.boundingBox.width > minFaceSize && face.boundingBox.height > minFaceSize
            }
            
            guard let firstQualityFace = qualityFaces.first else {
                // No quality faces found
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Crop the first quality face
            let croppedImage = self.cropFaceFromImage(image, faceObservation: firstQualityFace)
            DispatchQueue.main.async {
                completion(croppedImage)
            }
        }
        
        // Perform face detection on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func cropFaceFromImage(_ image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Convert Vision coordinates (bottom-left origin) to Core Graphics coordinates (top-left origin)
        let boundingBox = faceObservation.boundingBox
        let faceRect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        
        // Add padding around the face
        let padding: CGFloat = 0.4
        let paddedRect = CGRect(
            x: max(0, faceRect.origin.x - faceRect.width * padding),
            y: max(0, faceRect.origin.y - faceRect.height * padding),
            width: min(imageSize.width, faceRect.width * (1 + 2 * padding)),
            height: min(imageSize.height, faceRect.height * (1 + 2 * padding))
        )
        
        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: paddedRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
