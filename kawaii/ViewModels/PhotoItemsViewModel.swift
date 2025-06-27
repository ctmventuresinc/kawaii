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
    
    private let photoCacheManager = PhotoCacheManager()
    
    func prefillCacheForDate(_ date: Date) {
        photoCacheManager.prefillPhotosForDate(date)
    }
    
    func handleDateChange(_ newDate: Date) {
        print("🔍 DEBUG: Date changed to \(newDate)")
        photoCacheManager.prefillPhotosForDate(newDate)
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
                    
                    // Standardized size for all photo types - creates cohesive collaging experience
                    let size: CGFloat = CGFloat.random(in: 153...234)
                    
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
    
    func addPhotoItemWithForcedBackgroundRemoval(from image: UIImage, backgroundRemover: BackgroundRemover, completion: @escaping () -> Void) {
        // Force background removal for SVG cutout effect
        backgroundRemover.removeBackground(of: image) { processedImage in
            // Use processed image or fail gracefully
            guard let finalImage = processedImage else {
                print("🔍 DEBUG: Background removal failed for SVG cutout")
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let randomX = CGFloat.random(in: 100...(screenWidth - 100))
            let randomY = CGFloat.random(in: 100...(screenHeight - 200))
            
            // Always use frames for SVG cutout effect
            let frameShape = FaceFrameShape.allCases.randomElement()
            let size: CGFloat = CGFloat.random(in: 153...234)
            
            let photoItem = PhotoItem(
                image: finalImage,
                position: CGPoint(x: randomX, y: randomY),
                frameShape: frameShape,
                size: size
            )
            
            DispatchQueue.main.async {
                self.photoItems.append(photoItem)
                completion()
            }
        }
    }
    
    func addPhotoItem(from image: UIImage, actualMethod: PhotoRetrievalMethod, currentMethod: PhotoRetrievalMethod, backgroundRemover: BackgroundRemover, completion: @escaping () -> Void) {
        // Remove background from the image first
        backgroundRemover.removeBackground(of: image) { processedImage in
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
                shouldUseFrames = currentMethod != .recentPhotos
            case .recentPhotosWithSVG:
                // Intentional SVG recent photos - always use frames
                shouldUseFrames = true
            default:
                // Face crop modes - always use frames
                shouldUseFrames = true
            }
            
            let frameShape = shouldUseFrames ? FaceFrameShape.allCases.randomElement() : nil
            
            // Standardized size for all photo types - creates cohesive collaging experience
            let size: CGFloat = CGFloat.random(in: 153...234)
            
            let photoItem = PhotoItem(
                image: finalImage,
                position: CGPoint(x: randomX, y: randomY),
                frameShape: frameShape,
                size: size
            )
            
            // Only UI updates on main thread
            DispatchQueue.main.async {
                self.photoItems.append(photoItem)
                completion()
            }
        }
    }
    
    func addTestPhotoItem(backgroundRemover: BackgroundRemover, soundService: SoundService, dateSelection: DateSelectionViewModel, photoMode: PhotoMode, completion: @escaping (Bool) -> Void) {
        print("🔍 DEBUG: addTestElement() called - START")
        
        // Try cache first for instant response
        let currentDate = dateSelection.selectedDate
        if let cachedPhoto = photoCacheManager.getCachedPhotoInstantly(for: currentDate, photoMode: photoMode) {
            print("🔍 DEBUG: Using CACHED photo - instant response!")
            createPhotoItemFromCachedPhoto(cachedPhoto, photoMode: photoMode, soundService: soundService, completion: completion)
            return
        }
        
        // If cache miss and face mode was requested, try aggressive face search
        if photoMode == .faceOnly {
            print("🔍 DEBUG: Cache miss for face request - trying aggressive search")
            isLoading = true
            soundService.playLoadingSoundIfStillLoading { [weak self] in
                return self?.isLoading ?? false
            }
            
            Task {
                await photoCacheManager.ensureFacePhotosAvailable(for: currentDate)
                
                // Try cache again after aggressive search
                if let cachedPhoto = await MainActor.run(body: { 
                    photoCacheManager.getCachedPhotoInstantly(for: currentDate, photoMode: photoMode) 
                }) {
                    await MainActor.run {
                        self.isLoading = false
                        self.createPhotoItemFromCachedPhoto(cachedPhoto, photoMode: photoMode, soundService: soundService, completion: completion)
                    }
                    return
                }
                
                // Still no faces found, fall through to original slow path
                await MainActor.run {
                    print("🔍 DEBUG: Aggressive search failed - falling back to original slow path")
                }
            }
        }
        
        // Fallback to original slow path
        print("🔍 DEBUG: Cache miss - falling back to slow fetch")
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
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
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
                print("🔍 DEBUG: Any photo mode - selected photo at index \(randomIndex)")
                self.loadImageAndCreatePhotoItem(asset: randomAsset, backgroundRemover: backgroundRemover, soundService: soundService, method: .recentPhotos, completion: completion)
            case .mixed:
                // Weighted random: 30% face detection, 60% regular photo, 10% random photo with SVG cutout
                let randomValue = Int.random(in: 1...100)
                
                if randomValue <= 30 {
                    // 30% - Face detection photos (cropped faces with background removed)
                    print("🔍 DEBUG: Mixed mode - chose FACE DETECTION (30%)")
                    self.findPhotoWithFacesFromAssets(fetchResult, attempts: 0, maxAttempts: 50, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
                } else if randomValue <= 90 {
                    // 60% - Regular random photos (full photos, no processing)
                    print("🔍 DEBUG: Mixed mode - chose REGULAR PHOTO (60%)")
                    let randomIndex = Int.random(in: 0..<fetchResult.count)
                    let randomAsset = fetchResult.object(at: randomIndex)
                    self.loadImageAndCreatePhotoItem(asset: randomAsset, backgroundRemover: backgroundRemover, soundService: soundService, method: .recentPhotos, completion: completion)
                } else {
                    // 10% - Random photos with SVG cutout (background removed but not face-cropped)
                    print("🔍 DEBUG: Mixed mode - chose RANDOM PHOTO WITH SVG CUTOUT (10%)")
                    let randomIndex = Int.random(in: 0..<fetchResult.count)
                    let randomAsset = fetchResult.object(at: randomIndex)
                    self.loadImageAndCreatePhotoItemWithBackgroundRemoval(asset: randomAsset, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
                }
            }
        }
    }
    
    private func findPhotoWithFacesFromAssets(_ assets: PHFetchResult<PHAsset>, attempts: Int, maxAttempts: Int, backgroundRemover: BackgroundRemover, soundService: SoundService, completion: @escaping (Bool) -> Void) {
        guard attempts < maxAttempts, attempts < assets.count else {
            print("No faces found after \(attempts) attempts - falling back to regular photo")
            // Fallback to regular photo if no faces found
            let randomIndex = Int.random(in: 0..<assets.count)
            let randomAsset = assets.object(at: randomIndex)
            loadImageAndCreatePhotoItem(asset: randomAsset, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
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
                self?.createPhotoItemWithFrame(from: faceImage, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
            } else {
                // No faces in this image, try next one
                self?.findPhotoWithFacesFromAssets(assets, attempts: attempts + 1, maxAttempts: maxAttempts, backgroundRemover: backgroundRemover, soundService: soundService, completion: completion)
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
                self.addPhotoItem(from: image, actualMethod: method, currentMethod: method, backgroundRemover: backgroundRemover) {
                    // Play sound and show overlay (same as add button)
                    soundService.playMarioSuccessSound()
                    self.isLoading = false
                    completion(true)
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
                self.addPhotoItemWithForcedBackgroundRemoval(from: image, backgroundRemover: backgroundRemover) {
                    soundService.playMarioSuccessSound()
                    self.isLoading = false
                    completion(true)
                }
            }
        }
    }
    
    private func createPhotoItemWithFrame(from faceImage: UIImage, backgroundRemover: BackgroundRemover, soundService: SoundService, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            self.addPhotoItem(from: faceImage, actualMethod: .facePhotosLastMonth, currentMethod: .facePhotosLastMonth, backgroundRemover: backgroundRemover) {
                // Play sound and show overlay (same as add button)
                soundService.playMarioSuccessSound()
                self.isLoading = false
                completion(true)
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
    
    private func createPhotoItemFromCachedPhoto(_ cachedPhoto: PhotoCacheManager.PreprocessedPhoto, photoMode: PhotoMode, soundService: SoundService, completion: @escaping (Bool) -> Void) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let randomX = CGFloat.random(in: 100...(screenWidth - 100))
        let randomY = CGFloat.random(in: 100...(screenHeight - 200))
        
        // Determine final image and framing based on processing type
        let finalImage: UIImage
        let frameShape: FaceFrameShape?
        let size: CGFloat
        
        switch cachedPhoto.processingType {
        case .faceDetection:
            // Use face image with background removed, always framed
            // Background removal is guaranteed to exist (enforced in cache)
            finalImage = cachedPhoto.backgroundRemovedImage!
            frameShape = FaceFrameShape.allCases.randomElement()
            size = CGFloat.random(in: 153...234) // Face crop size range
        case .backgroundOnly:
            // Use background removed image, WITH frame (for visual variety)
            // Background removal is guaranteed to exist (enforced in cache)
            finalImage = cachedPhoto.backgroundRemovedImage!
            frameShape = FaceFrameShape.allCases.randomElement()
            size = CGFloat.random(in: 220...350)
        case .none:
            // Use background removed image (all photos get background removal), no frame
            // Background removal is guaranteed to exist (enforced in cache)
            finalImage = cachedPhoto.backgroundRemovedImage!
            frameShape = nil
            size = CGFloat.random(in: 153...220)
        }
        
        let photoItem = PhotoItem(
            image: finalImage,
            position: CGPoint(x: randomX, y: randomY),
            frameShape: frameShape,
            size: size
        )
        
        photoItems.append(photoItem)
        
        // Play sound effect like original code
        soundService.playMarioSuccessSound()
        completion(true)
    }
    
    func convertToFramedPhoto(at index: Int) {
        guard index < photoItems.count else { return }
        
        // Create new PhotoItem with frame
        let currentItem = photoItems[index]
        let frameShape = FaceFrameShape.allCases.randomElement()
        let newSize = CGFloat.random(in: 153...234) // Face crop size range
        
        // Update the existing PhotoItem
        photoItems[index] = PhotoItem(
            image: currentItem.image,
            position: currentItem.position,
            frameShape: frameShape,
            size: newSize
        )
    }

}
