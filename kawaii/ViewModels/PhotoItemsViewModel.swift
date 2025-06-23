//
//  PhotoItemsManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import Photos

@MainActor
class PhotoItemsViewModel: ObservableObject {
    @Published var photoItems: [PhotoItem] = []
    
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
    
    func addTestPhotoItem(backgroundRemover: BackgroundRemover, completion: @escaping (Bool) -> Void) {
        print("🔍 DEBUG: addTestElement() called - START")
        
        // Move ALL Photos framework operations to background queue
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 DEBUG: Now on background queue")
            
            // Get the most recent photo in the simplest way possible
            print("🔍 DEBUG: About to create fetch options")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1 // Just get the most recent
            
            print("🔍 DEBUG: About to call PHAsset.fetchAssets")
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("🔍 DEBUG: PHAsset.fetchAssets completed, found \(fetchResult.count) assets")
        
            guard fetchResult.count > 0 else {
                print("🔍 DEBUG: No photos found")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let mostRecentAsset = fetchResult.object(at: 0)
            print("🔍 DEBUG: Got most recent asset, about to request image")
            
            // Request the image at high quality (matching regular Add button)
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            // Load at display resolution (450px max) * 2 for retina * screen scale
            let maxDisplaySize: CGFloat = 450 // Same as regular Add button
            let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
            
            PHImageManager.default().requestImage(
                for: mostRecentAsset,
                targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                print("🔍 DEBUG: Image request completed")
                guard let image = image else {
                    print("🔍 DEBUG: No image returned")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                print("🔍 DEBUG: Got image, applying background removal")
                // Apply background removal to make it transparent/cut out
                backgroundRemover.removeBackground(of: image) { processedImage in
                    print("🔍 DEBUG: Background removal completed")
                    let finalImage = processedImage ?? image // Use original if background removal fails
                    
                    DispatchQueue.main.async {
                        print("🔍 DEBUG: Back on main queue with processed image")
                        let screenWidth = UIScreen.main.bounds.width
                        let screenHeight = UIScreen.main.bounds.height
                        let randomX = CGFloat.random(in: 100...(screenWidth - 100))
                        let randomY = CGFloat.random(in: 100...(screenHeight - 200))
                        
                        // Add SVG frames like regular Add button
                        let frameShape = FaceFrameShape.allCases.randomElement()
                        print("🔍 DEBUG: Added SVG frame: \(frameShape != nil ? "irregularBurst" : "none")")
                        
                        // Use same size range as regular Add button
                        let size: CGFloat = CGFloat.random(in: 153...234)
                        
                        let testPhotoItem = PhotoItem(
                            image: finalImage,
                            position: CGPoint(x: randomX, y: randomY),
                            frameShape: frameShape,
                            size: size
                        )
                        
                        print("🔍 DEBUG: About to append PhotoItem with cut-out background")
                        self.photoItems.append(testPhotoItem)
                        
                        print("🔍 DEBUG: PhotoItem appended - END")
                        completion(true)
                    }
                }
            }
        }
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
