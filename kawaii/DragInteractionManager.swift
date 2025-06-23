//
//  DragInteractionManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

// Drag interaction manager to handle all photo drag states and actions
@MainActor
class DragInteractionManager: ObservableObject {
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
    
    // Action closures
    var isOverTrashBin: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var isOverShareButton: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var isOverStarButton: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var deletePhotoItem: ((Int) -> Void)?
    var sharePhotoItem: ((PhotoItem) -> Void)?
    var convertToFramedPhoto: ((Int) -> Void)?
    
    func updateDragStates(isDragging: Bool) {
        if isDragging {
            trashBinOpacity = 1.0
            trashBinScale = 1.0
            starButtonOpacity = 1.0
            starButtonScale = 1.0
            shareButtonOpacity = 1.0
            shareButtonScale = 1.0
        } else {
            trashBinOpacity = 0.0
            trashBinScale = 0.8
            starButtonOpacity = 0.0
            starButtonScale = 0.8
            shareButtonOpacity = 0.0
            shareButtonScale = 0.8
        }
    }
    
    func resetDragStates() {
        isDraggingAny = false
        isHoveringOverTrash = false
        isHoveringOverStar = false
        isHoveringOverShare = false
    }
}
