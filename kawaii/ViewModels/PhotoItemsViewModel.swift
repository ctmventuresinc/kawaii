//
//  PhotoItemsManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import Photos
import Vision

@MainActor
class PhotoItemsViewModel: ObservableObject {
    @Published var photoItems: [PhotoItem] = []
    @Published var isLoading = false
    
    // CENTRALIZED DECISION SERVICE - SINGLE SOURCE OF TRUTH
    private let photoTypeDecisionService = PhotoTypeDecisionService()
    
    func prefillCacheForDate(_ date: Date) {
        // Cache system removed - this function is now a no-op
    }
    
    func handleDateChange(_ newDate: Date) {
        print("🔍 DEBUG: Date changed to \(newDate)")
        // Cache system removed - no action needed on date change
    }
    
    func fetchAndAddRandomPhoto(photoViewModel: PhotoViewModel, soundService: SoundService) {
        isLoading = true
        soundService.playLoadingSoundIfStillLoading { [weak self] in
            return self?.isLoading ?? false
        }
        
        photoViewModel.fetchRandomPhoto { image, actualMethod in
            // Keep background removal and PhotoItem creation off main thread
            if let image = image {
                // Remove background from the image first
                photoViewModel.backgroundRemover.removeBackground(of: image) { processedImage in
                    let finalImage = processedImage ?? image // Use original if background removal fails
                    
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    let randomX = CGFloat.random(in: 100...(screenWidth - 100))
                    let randomY = CGFloat.random(in: 100...(screenHeight - 200))
                    
                    // Determine frame usage
                    let shouldUseFrames: Bool
                    switch actualMethod {
                    case .recentPhotos:
                        // Regular recent photos - no frames unless fallback from face crop mode
                        shouldUseFrames = photoViewModel.currentMethod != .recentPhotos
                    case .recentPhotosWithSVG:
                        // Intentional SVG recent photos - always use frames
                        shouldUseFrames = true
                    default:
                        // Face crop modes - always use frames
                        shouldUseFrames = true
                    }
                    
                    let frameShape = shouldUseFrames ? FaceFrameShape.allCases.randomElement() : nil
                    
                    // Size based on frame type
                    let size: CGFloat = frameShape == nil ? 
                        CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.regularPhotoRange) :  // Regular photos (no frames) - larger
                        CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.framedPhotoRange)    // Framed photos - smaller
                    
                    let photoItem = PhotoItem(
                        image: finalImage,
                        position: CGPoint(x: randomX, y: randomY),
                        frameShape: frameShape,
                        size: size
                    )
                    
                    // Only UI updates on main thread
                    DispatchQueue.main.async {
                        self.photoItems.append(photoItem)
                        
                        // Loading complete - photo successfully added
                        self.isLoading = false
                        
                        // Play random Mario success sound
                        soundService.playMarioSuccessSound()
                    }
                }
            } else {
                // This should never happen now due to fallback system
                print("No photos found even after fallback - check photo library permissions")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func addPhotoItemWithForcedBackgroundRemoval(from image: UIImage, backgroundRemover: BackgroundRemover, completion: @escaping (Bool) -> Void) {
        // Force background removal for SVG cutout effect
        backgroundRemover.removeBackground(of: image) { processedImage in
            // Use processed image or fail gracefully
            guard let finalImage = processedImage else {
                print("🔍 DEBUG: Background removal failed for SVG cutout")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let randomX = CGFloat.random(in: 100...(screenWidth - 100))
            let randomY = CGFloat.random(in: 100...(screenHeight - 200))
            
            // Always use frames for SVG cutout effect
            let frameShape = FaceFrameShape.allCases.randomElement()
            let size: CGFloat = CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.framedPhotoRange)
            
            let photoItem = PhotoItem(
                image: finalImage,
                position: CGPoint(x: randomX, y: randomY),
                frameShape: frameShape,
                size: size
            )
            
            DispatchQueue.main.async {
                self.photoItems.append(photoItem)
                completion(true)
            }
        }
    }
    
    func addPhotoItemWithBackgroundRemovalNoFrames(from image: UIImage, backgroundRemover: BackgroundRemover, completion: @escaping (Bool) -> Void) {
        // Force background removal but no frames for regular photos
        backgroundRemover.removeBackground(of: image) { processedImage in
            // Only proceed if background removal succeeded
            guard let finalImage = processedImage else {
                print("🔍 DEBUG: Background removal failed - photo cannot be cut out, skipping")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let randomX = CGFloat.random(in: 100...(screenWidth - 100))
            let randomY = CGFloat.random(in: 100...(screenHeight - 200))
            
            // No frames for regular photos
            let size: CGFloat = CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.regularPhotoRange)
            
            let photoItem = PhotoItem(
                image: finalImage,
                position: CGPoint(x: randomX, y: randomY),
                frameShape: nil,
                size: size
            )
            
            DispatchQueue.main.async {
                self.photoItems.append(photoItem)
                completion(true)
            }
        }
    }
    
    func addPhotoItem(from image: UIImage, actualMethod: PhotoRetrievalMethod, currentMethod: PhotoRetrievalMethod, backgroundRemover: BackgroundRemover, completion: @escaping (Bool) -> Void) {
        // Remove background from the image first
        backgroundRemover.removeBackground(of: image) { processedImage in
            // Only proceed if background removal succeeded
            guard let finalImage = processedImage else {
                print("🔍 DEBUG: Background removal failed for face photo")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let randomX = CGFloat.random(in: 100...(screenWidth - 100))
            let randomY = CGFloat.random(in: 100...(screenHeight - 200))
            
            // Determine frame usage
            let shouldUseFrames: Bool
            switch actualMethod {
            case .recentPhotos:
                // Regular recent photos - no frames unless fallback from face crop mode
                shouldUseFrames = currentMethod != .recentPhotos
            case .recentPhotosWithSVG:
                // Intentional SVG recent photos - always use frames
                shouldUseFrames = true
            default:
                // Face crop modes - always use frames
                shouldUseFrames = true
            }
            
            let frameShape = shouldUseFrames ? FaceFrameShape.allCases.randomElement() : nil
            
            // Size based on frame type
            let size: CGFloat = frameShape == nil ? 
                CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.regularPhotoAltRange) :  // Regular photos (no frames) - larger
                CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.framedPhotoRange)    // Framed photos - smaller
            
            let photoItem = PhotoItem(
                image: finalImage,
                position: CGPoint(x: randomX, y: randomY),
                frameShape: frameShape,
                size: size
            )
            
            // Only UI updates on main thread
            DispatchQueue.main.async {
                self.photoItems.append(photoItem)
                completion(true)
            }
        }
    }
    
    func addTestPhotoItem(backgroundRemover: BackgroundRemover, soundService: SoundService, dateSelection: DateSelectionViewModel, photoMode: PhotoMode, completion: @escaping (Bool) -> Void) {
        print("🔍 DEBUG: addTestElement() called - START")
        
        // No cache system - use direct photo fetching
        print("🔍 DEBUG: Using direct photo fetching")
        isLoading = true
        soundService.playLoadingSoundIfStillLoading { [weak self] in
            return self?.isLoading ?? false
        }
        
        // Move ALL Photos framework operations to background queue
        Task {
            print("🔍 DEBUG: Now on background queue")
            
            // Get random face photos from selected date
            let debugDate = await MainActor.run { dateSelection.getDebugDate() }
            print("🔍 DEBUG: About to create fetch options for date: \(debugDate)")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            // Filter for photos from the selected date and exclude screenshots
            let dateRange = await MainActor.run { dateSelection.getCurrentDateRange() }
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@ AND NOT (mediaSubtypes & %d) != 0", 
                                               dateRange.start as NSDate, dateRange.end as NSDate, PHAssetMediaSubtype.photoScreenshot.rawValue)
            fetchOptions.fetchLimit = 100 // Smaller limit since it's just one day
            
            print("🔍 DEBUG: About to call PHAsset.fetchAssets")
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("🔍 DEBUG: PHAsset.fetchAssets completed, found \(fetchResult.count) assets")
        
            guard fetchResult.count > 0 else {
                let debugDate = await MainActor.run { dateSelection.getDebugDate() }
                print("🔍 DEBUG: No photos found from selected date: \(debugDate)")
                print("🔍 DEBUG: Falling back to any photo from library")
                
                // FALLBACK FOR APP STORE REVIEW: Ensures app always shows photos even with limited library access
                let fallbackOptions = PHFetchOptions()
                fallbackOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fallbackOptions.predicate = NSPredicate(format: "NOT (mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
                fallbackOptions.fetchLimit = 100
                
                let fallbackResult = PHAsset.fetchAssets(with: .image, options: fallbackOptions)
                print("🔍 DEBUG: Fallback found \(fallbackResult.count) photos")
                
                guard fallbackResult.count > 0 else {
                    print("🔍 DEBUG: No photos found in entire library")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(false)
                    }
                    return
                }
                
                let randomAsset = { fallbackResult.object(at: Int.random(in: 0..<fallbackResult.count)) }
                
                switch photoMode {
                case .faceOnly:
                    self.findPhotoWithFacesFromAssets(fallbackResult, attempts: 0, maxAttempts: 50, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
                case .anyPhoto:
                    self.tryMultiplePhotosWithRetry(from: fallbackResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "regular", photoProcessor: { asset, bgRemover, soundSvc, completion in
                        self.loadImageAndCreatePhotoItem(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, method: .recentPhotos, completion: completion)
                    }, completion: completion)
                case .mixed:
                    switch PhotoTypeDecisionService().getPhotoTypeForMixedMode() {
                    case .facesWithFrames:
                        self.findPhotoWithFacesFromAssets(fallbackResult, attempts: 0, maxAttempts: 50, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
                    case .regularWithFrames:
                        self.tryMultiplePhotosWithRetry(from: fallbackResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "SVG", photoProcessor: { asset, bgRemover, soundSvc, completion in
                            self.loadImageAndCreatePhotoItemWithBackgroundRemoval(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, completion: completion)
                        }, completion: completion)
                    case .none:
                        self.tryMultiplePhotosWithRetry(from: fallbackResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "regular", photoProcessor: { asset, bgRemover, soundSvc, completion in
                            self.loadImageAndCreatePhotoItem(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, method: .recentPhotos, completion: completion)
                        }, completion: completion)
                    }
                }
                return
            }
            
            switch photoMode {
            case .faceOnly:
                // Face detection only
                self.findPhotoWithFacesFromAssets(fetchResult, attempts: 0, maxAttempts: 50, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
            case .anyPhoto:
                // Random photo only
                let randomIndex = Int.random(in: 0..<fetchResult.count)
                let randomAsset = fetchResult.object(at: randomIndex)
                print("🔍 DEBUG: Any photo mode - trying photos until one can be cut out")
                self.tryMultiplePhotosWithRetry(from: fetchResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "regular", photoProcessor: { asset, bgRemover, soundSvc, completion in
                    self.loadImageAndCreatePhotoItem(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, method: .recentPhotos, completion: completion)
                }, completion: completion)
            case .mixed:
                // USE CENTRALIZED DECISION SERVICE - NO MORE HARDCODED FALLBACK PERCENTAGES!
                let requestedType = await MainActor.run { 
                    photoTypeDecisionService.getPhotoTypeForMixedMode() 
                }
                await MainActor.run { 
                    photoTypeDecisionService.logCurrentConfig() 
                }
                
                switch requestedType {
                case .facesWithFrames:
                    print("🔍 DEBUG: Fallback using centralized service - chose FACES WITH FRAMES")
                    self.findPhotoWithFacesFromAssets(fetchResult, attempts: 0, maxAttempts: 50, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
                case .none:
                    print("🔍 DEBUG: Fallback using centralized service - chose REGULAR PHOTO")
                    self.tryMultiplePhotosWithRetry(from: fetchResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "regular", photoProcessor: { asset, bgRemover, soundSvc, completion in
                        self.loadImageAndCreatePhotoItem(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, method: .recentPhotos, completion: completion)
                    }, completion: completion)
                case .regularWithFrames:
                    print("🔍 DEBUG: Fallback using centralized service - chose REGULAR PHOTOS WITH FRAMES")
                    self.tryMultiplePhotosWithRetry(from: fetchResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "SVG", photoProcessor: { asset, bgRemover, soundSvc, completion in
                        self.loadImageAndCreatePhotoItemWithBackgroundRemoval(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, completion: completion)
                    }, completion: completion)
                }
            }
        }
    }
    
    private func findUnusedAsset(from fetchResult: PHFetchResult<PHAsset>) -> PHAsset? {
        // Try up to 10 times to find an unused asset
        let maxAttempts = FeatureFlags.shared.preventDuplicatePhotos ? 10 : 1
        for _ in 0..<maxAttempts {
            let randomIndex = Int.random(in: 0..<fetchResult.count)
            let asset = fetchResult.object(at: randomIndex)
            
            if !FeatureFlags.shared.isAssetUsed(asset.localIdentifier) {
                FeatureFlags.shared.markAssetAsUsed(asset.localIdentifier)
                return asset
            }
        }
        return nil // All attempts failed to find unused asset
    }
    
    private func findPhotoWithFacesFromAssets(_ assets: PHFetchResult<PHAsset>, attempts: Int, maxAttempts: Int, backgroundRemover: BackgroundRemover, soundService: SoundService, completion: @escaping (Bool) -> Void) {
        guard attempts < maxAttempts, attempts < assets.count else {
            print("No faces found after \(attempts) attempts - falling back to regular photo")
            // Fallback to regular photo if no faces found
            let randomIndex = Int.random(in: 0..<assets.count)
            let randomAsset = assets.object(at: randomIndex)
            // Fallback when no faces found - try multiple photos
            let fallbackResult = PHAsset.fetchAssets(with: .image, options: nil)
            tryMultiplePhotosWithRetry(from: fallbackResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: 0, maxAttempts: 10, photoType: "regular", photoProcessor: { asset, bgRemover, soundSvc, completion in
                self.loadImageAndCreatePhotoItem(asset: asset, backgroundRemover: bgRemover, soundService: soundSvc, method: .recentPhotos, completion: completion)
            }, completion: completion)
            return
        }
        
        let randomIndex = Int.random(in: 0..<assets.count)
        let asset = assets.object(at: randomIndex)
        
        // Skip screenshots
        if asset.mediaSubtypes.contains(.photoScreenshot) {
            findPhotoWithFacesFromAssets(assets, attempts: attempts + 1, maxAttempts: maxAttempts, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
            return
        }
        
        // Load image and detect faces
        loadImageAndDetectFaces(asset: asset) { [weak self] faceImage in
            if let faceImage = faceImage {
                // Found a face! Create photo item with frame
                self?.createPhotoItemWithFrame(from: faceImage, backgroundRemover: backgroundRemover, soundService: soundService) { success in
                    if success {
                        completion(true)
                    } else {
                        // Background removal failed on face photo, try next one
                        print("🔍 DEBUG: Face photo background removal failed, trying another photo")
                        self?.findPhotoWithFacesFromAssets(assets, attempts: attempts + 1, maxAttempts: maxAttempts, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
                    }
                }
            } else {
                // No faces in this image, try next one
                self?.findPhotoWithFacesFromAssets(assets, attempts: attempts + 1, maxAttempts: maxAttempts, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
            }
        }
    }
    
    private func tryMultiplePhotosWithRetry(
        from fetchResult: PHFetchResult<PHAsset>, 
        backgroundRemover: BackgroundRemover, 
        soundService: SoundService, 
        attempts: Int, 
        maxAttempts: Int, 
        photoType: String,
        photoProcessor: @escaping (PHAsset, BackgroundRemover, SoundService, @escaping (Bool) -> Void) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        guard attempts < maxAttempts, fetchResult.count > 0 else {
            print("🔍 DEBUG: Could not find any \(photoType) photos that can be cut out after \(attempts) attempts")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        print("🔍 DEBUG: \(photoType) retry attempt \(attempts + 1)/\(maxAttempts)")
        
        let randomIndex = Int.random(in: 0..<fetchResult.count)
        let randomAsset = fetchResult.object(at: randomIndex)
        
        photoProcessor(randomAsset, backgroundRemover, soundService) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                // Try another photo with a small delay to prevent overwhelming the system
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.tryMultiplePhotosWithRetry(from: fetchResult, backgroundRemover: backgroundRemover, soundService: soundService, attempts: attempts + 1, maxAttempts: maxAttempts, photoType: photoType, photoProcessor: photoProcessor, completion: completion)
                }
            }
        }
    }
    
    private func loadImageAndCreatePhotoItem(asset: PHAsset, backgroundRemover: BackgroundRemover, soundService: SoundService, method: PhotoRetrievalMethod = .facePhotosLastMonth, completion: @escaping (Bool) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let maxDisplaySize: CGFloat = 450
        let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.addPhotoItemWithBackgroundRemovalNoFrames(from: image, backgroundRemover: backgroundRemover) { success in
                    if success {
                        // Play sound and show overlay (same as add button)
                        soundService.playMarioSuccessSound()
                        self.isLoading = false
                        completion(true)
                    } else {
                        // Background removal failed, try another photo
                        print("🔍 DEBUG: Background removal failed, retrying with different photo")
                        self.isLoading = false
                        completion(false)
                    }
                }
            }
        }
    }
    
    private func loadImageAndCreatePhotoItemWithBackgroundRemoval(asset: PHAsset, backgroundRemover: BackgroundRemover, soundService: SoundService, completion: @escaping (Bool) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let maxDisplaySize: CGFloat = 450
        let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }
            
            // Force background removal for SVG cutout effect
            DispatchQueue.main.async {
                self.addPhotoItemWithForcedBackgroundRemoval(from: image, backgroundRemover: backgroundRemover) { success in
                    if success {
                        soundService.playMarioSuccessSound()
                        self.isLoading = false
                        completion(true)
                    } else {
                        print("🔍 DEBUG: SVG background removal failed, retrying with different photo")
                        self.isLoading = false
                        completion(false)
                    }
                }
            }
        }
    }
    
    private func createPhotoItemWithFrame(from faceImage: UIImage, backgroundRemover: BackgroundRemover, soundService: SoundService, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.addPhotoItem(from: faceImage, actualMethod: .facePhotosLastMonth, currentMethod: .facePhotosLastMonth, backgroundRemover: backgroundRemover) { success in
                if success {
                    // Play sound and show overlay (same as add button)
                    soundService.playMarioSuccessSound()
                    self.isLoading = false
                    completion(true)
                } else {
                    print("🔍 DEBUG: Face photo background removal failed")
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }
    
    private func loadImageAndDetectFaces(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let maxFaceDisplaySize: CGFloat = 234
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
            
            // Use the same face detection logic as PhotoViewModel
            self.detectAndCropFace(from: fullImage, completion: completion)
        }
    }
    
    // Copy face detection logic from PhotoViewModel
    private func detectAndCropFace(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let minFaceSize: CGFloat = 0.10
            let qualityFaces = observations.filter { face in
                return face.boundingBox.width > minFaceSize && face.boundingBox.height > minFaceSize
            }
            
            guard let firstQualityFace = qualityFaces.first else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let croppedImage = self.cropFaceFromImage(image, faceObservation: firstQualityFace)
            DispatchQueue.main.async {
                completion(croppedImage)
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
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
    
    func deletePhotoItem(at index: Int) {
        // Remove item after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if index < self.photoItems.count {
                self.photoItems.remove(at: index)
            }
        }
    }
    

    
    func convertToFramedPhoto(at index: Int) {
        guard index < photoItems.count else { return }
        
        // Create new PhotoItem with frame
        let currentItem = photoItems[index]
        let frameShape = FaceFrameShape.allCases.randomElement()
        let newSize = CGFloat.random(in: PhotoTypeDecisionService.PhotoSizeConfig.framedPhotoRange) // Face crop size range
        
        // Update the existing PhotoItem
        photoItems[index] = PhotoItem(
            image: currentItem.image,
            position: currentItem.position,
            frameShape: frameShape,
            size: newSize
        )
    }

}
