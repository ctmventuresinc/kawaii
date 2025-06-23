//
//  ShareService.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

@MainActor
class ShareService: ObservableObject {
    @Published var showShareSheet = false
    @Published var shareImage: UIImage?
    @Published var shareText: String?
    
    var animationViewModel: AnimationViewModel?
    var dragViewModel: DragInteractionViewModel?
    
    func sharePhotoItem(_ photoItem: PhotoItem) {
        // Trigger glow animation
        animationViewModel?.triggerShareGlowAnimation()
        
        // Scale effect for share button
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dragViewModel?.shareButtonScale = 1.1
        }
        
        // Generate image to share
        Task {
            await generateShareImage(from: photoItem)
        }
        
        // Reset share button scale after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.dragViewModel?.shareButtonScale = 1.0
            }
        }
    }
    
    private func generateShareImage(from photoItem: PhotoItem) async {
        // Create a renderer to generate the image
        let renderer = ImageRenderer(content: 
            Group {
                if let frameShape = photoItem.frameShape {
                    // Face crops with exciting frames
                    switch frameShape {
                    case .irregularBurst:
                        ZStack {
                            // Outermost stroke using color combination
                            Image(photoItem.shapeName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: photoItem.size + 160, height: photoItem.size + 160)
                                .foregroundColor(photoItem.strokeColor)
                                .shadow(color: photoItem.strokeColor.opacity(0.6), radius: 12, x: 0, y: 0)
                            
                            // Background shape using color combination
                            Image(photoItem.shapeName)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: photoItem.size + 120, height: photoItem.size + 120)
                                .foregroundColor(photoItem.backgroundColor)
                                .shadow(color: photoItem.backgroundColor.opacity(0.6), radius: 12, x: 0, y: 0)
                            
                            // Photo on top - masked by outer stroke shape with color filter
                            Image(uiImage: photoItem.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: photoItem.size, height: photoItem.size)
                                .applyPhotoFilter(photoItem.photoFilter)
                                .mask(
                                    Image(photoItem.shapeName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: photoItem.size + 160, height: photoItem.size + 160)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                } else {
                    // Regular photos with rounded corners
                    Image(uiImage: photoItem.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: photoItem.size, height: photoItem.size)
                        .cornerRadius(16)
                }
            }
        )
        
        renderer.scale = 3.0 // High resolution for sharing
        
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
    }
}
