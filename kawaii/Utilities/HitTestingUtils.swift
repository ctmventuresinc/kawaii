//
//  HitTestingUtils.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

// Hit testing utilities for collision detection
struct HitTestingUtils {
    
    // MARK: - Target Definitions
    enum TargetButton {
        case trash
        case star  
        case share
        
        var radius: CGFloat { 30 } // All buttons are 60x60, so radius is 30
        
        func center(in geometry: GeometryProxy) -> CGPoint {
            switch self {
            case .trash:
                return CGPoint(x: 70, y: geometry.size.height - 50) // 40 padding + 30 radius
            case .star:
                return CGPoint(x: geometry.size.width - 70, y: geometry.size.height - 50) // 40 padding + 30 radius from right
            case .share:
                return CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 50) // Center horizontally, same vertical position
            }
        }
    }
    
    // MARK: - Generic Collision Detection
    static func isOver(
        target: TargetButton,
        position: CGPoint,
        photoItem: PhotoItem,
        geometry: GeometryProxy,
        tolerance: CGFloat = -5 // Negative value makes it less sensitive
    ) -> Bool {
        let targetCenter = target.center(in: geometry)
        let targetRadius = target.radius
        
        // Calculate PhotoItem's effective radius based on type and target
        let photoItemRadius = calculatePhotoItemRadius(photoItem: photoItem, target: target)
        
        // Calculate distance between position and target center
        let distance = sqrt(pow(position.x - targetCenter.x, 2) + pow(position.y - targetCenter.y, 2))
        let totalRadius = targetRadius + photoItemRadius + tolerance
        
        return distance <= totalRadius
    }
    
    // MARK: - Helper Methods
    private static func calculatePhotoItemRadius(photoItem: PhotoItem, target: TargetButton) -> CGFloat {
        switch target {
        case .trash, .share:
            // Trash and share buttons work with both framed and regular photos
            if photoItem.frameShape != nil {
                // Face crops with frames - use background shape size for less sensitivity
                return (photoItem.size + 60) / 2
            } else {
                // Regular photos
                return photoItem.size / 2
            }
            
        case .star:
            // Star button only works with regular photos (converts them to framed)
            return photoItem.size / 2
        }
    }
    
    // MARK: - Convenience Methods
    static func isOverTrashBin(position: CGPoint, photoItem: PhotoItem, geometry: GeometryProxy) -> Bool {
        return isOver(target: .trash, position: position, photoItem: photoItem, geometry: geometry)
    }
    
    static func isOverStarButton(position: CGPoint, photoItem: PhotoItem, geometry: GeometryProxy) -> Bool {
        return isOver(target: .star, position: position, photoItem: photoItem, geometry: geometry)
    }
    
    static func isOverShareButton(position: CGPoint, photoItem: PhotoItem, geometry: GeometryProxy) -> Bool {
        return isOver(target: .share, position: position, photoItem: photoItem, geometry: geometry)
    }
}
