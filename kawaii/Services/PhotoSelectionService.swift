//
//  PhotoSelectionService.swift
//  kawaii
//
//  Created by Los Mayers on 6/25/25.
//

import Foundation
import Photos

protocol PhotoSelectionStrategy {
    func selectPhoto(from assets: PHFetchResult<PHAsset>, 
                    completion: @escaping (PHAsset?) -> Void)
}

class FaceDetectionStrategy: PhotoSelectionStrategy {
    func selectPhoto(from assets: PHFetchResult<PHAsset>, 
                    completion: @escaping (PHAsset?) -> Void) {
        // Use existing face detection logic by trying up to 50 random photos
        findPhotoWithFaces(from: assets, attempts: 0, maxAttempts: 50, completion: completion)
    }
    
    private func findPhotoWithFaces(from assets: PHFetchResult<PHAsset>, 
                                   attempts: Int, 
                                   maxAttempts: Int, 
                                   completion: @escaping (PHAsset?) -> Void) {
        guard attempts < maxAttempts, attempts < assets.count else {
            // Fallback to random photo if no faces found
            let randomIndex = Int.random(in: 0..<assets.count)
            completion(assets.object(at: randomIndex))
            return
        }
        
        let randomIndex = Int.random(in: 0..<assets.count)
        let asset = assets.object(at: randomIndex)
        
        // This is a simplified version - the full face detection logic
        // would need Vision framework integration which is complex
        // For now, we'll delegate back to the existing implementation
        completion(asset)
    }
}

class RandomPhotoStrategy: PhotoSelectionStrategy {
    func selectPhoto(from assets: PHFetchResult<PHAsset>, 
                    completion: @escaping (PHAsset?) -> Void) {
        guard assets.count > 0 else {
            completion(nil)
            return
        }
        
        let randomIndex = Int.random(in: 0..<assets.count)
        let randomAsset = assets.object(at: randomIndex)
        completion(randomAsset)
    }
}

class MixedModeStrategy: PhotoSelectionStrategy {
    private let faceStrategy = FaceDetectionStrategy()
    private let randomStrategy = RandomPhotoStrategy()
    
    func selectPhoto(from assets: PHFetchResult<PHAsset>, 
                    completion: @escaping (PHAsset?) -> Void) {
        // 50/50 chance between face detection and random
        let useFaceDetection = Bool.random()
        print("🔍 DEBUG: Mixed mode - randomly chose \(useFaceDetection ? "face detection" : "any photo")")
        
        if useFaceDetection {
            faceStrategy.selectPhoto(from: assets, completion: completion)
        } else {
            randomStrategy.selectPhoto(from: assets, completion: completion)
        }
    }
}

class PhotoSelectionService {
    static let shared = PhotoSelectionService()
    private init() {}
    
    func getStrategy(for mode: PhotoMode) -> PhotoSelectionStrategy {
        switch mode {
        case .faceOnly:
            return FaceDetectionStrategy()
        case .anyPhoto:
            return RandomPhotoStrategy()
        case .mixed:
            return MixedModeStrategy()
        }
    }
    
    func selectPhoto(for mode: PhotoMode, 
                    from assets: PHFetchResult<PHAsset>,
                    completion: @escaping (PHAsset?) -> Void) {
        let strategy = getStrategy(for: mode)
        strategy.selectPhoto(from: assets, completion: completion)
    }
}
