//
//  DragInteractionManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

// Drag interaction manager to handle all photo drag states and actions
@MainActor
class DragInteractionViewModel: ObservableObject {
    @Published var isDraggingAny = false
    @Published var isHoveringOverTrash = false
    @Published var isHoveringOverStar = false
    @Published var isHoveringOverShare = false
    @Published var trashBinOpacity: Double = 0.0
    @Published var trashBinScale: CGFloat = 1.0
    @Published var starButtonOpacity: Double = 0.0
    @Published var starButtonScale: CGFloat = 1.0
    @Published var shareButtonOpacity: Double = 0.0
    @Published var shareButtonScale: CGFloat = 1.0
    @Published var faceButtonOpacity: Double = 1.0
    @Published var faceButtonScale: CGFloat = 1.0
    @Published var rewindButtonOpacity: Double = 1.0
    @Published var rewindButtonScale: CGFloat = 1.0
    
    // Action closures
    var isOverTrashBin: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var isOverShareButton: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var isOverStarButton: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var deletePhotoItem: ((Int) -> Void)?
    var sharePhotoItem: ((PhotoItem) -> Void)?
    var convertToFramedPhoto: ((Int) -> Void)?
    
    func updateDragStates(isDragging: Bool) {
        if isDragging {
            // Show drag targets (trash, star, share)
            trashBinOpacity = 1.0
            trashBinScale = 1.0
            starButtonOpacity = 1.0
            starButtonScale = 1.0
            shareButtonOpacity = 1.0
            shareButtonScale = 1.0
            
            // Hide interface buttons (face, rewind)
            faceButtonOpacity = 0.0
            faceButtonScale = 0.8
            rewindButtonOpacity = 0.0
            rewindButtonScale = 0.8
        } else {
            // Hide drag targets
            trashBinOpacity = 0.0
            trashBinScale = 0.8
            starButtonOpacity = 0.0
            starButtonScale = 0.8
            shareButtonOpacity = 0.0
            shareButtonScale = 0.8
            
            // Show interface buttons
            faceButtonOpacity = 1.0
            faceButtonScale = 1.0
            rewindButtonOpacity = 1.0
            rewindButtonScale = 1.0
        }
    }
    
    func resetDragStates() {
        isDraggingAny = false
        isHoveringOverTrash = false
        isHoveringOverStar = false
        isHoveringOverShare = false
    }
}
