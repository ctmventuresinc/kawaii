//
//  AnimationManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

@MainActor
class AnimationManager: ObservableObject {
    // Trash animation states
    @Published var poofScale: CGFloat = 0.0
    @Published var poofOpacity: Double = 0.0
    
    // Star animation states
    @Published var sparkleScale: CGFloat = 0.0
    @Published var sparkleOpacity: Double = 0.0
    
    // Share animation states
    @Published var shareGlowScale: CGFloat = 0.0
    @Published var shareGlowOpacity: Double = 0.0
    
    // Add button animation states
    @Published var addButtonScale: CGFloat = 1.0
    @Published var addButtonOpacity: Double = 1.0
    
    func triggerPoofAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            poofScale = 1.0
            poofOpacity = 1.0
        }
        
        // Reset animations after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.poofOpacity = 0.0
            }
            
            // Reset poof scale for next use
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.poofScale = 0.0
            }
        }
    }
    
    func triggerSparkleAnimation() {
        withAnimation(.easeOut(duration: 0.4)) {
            sparkleScale = 1.0
            sparkleOpacity = 1.0
        }
        
        // Reset animations after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.sparkleOpacity = 0.0
            }
            
            // Reset sparkle scale for next use
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sparkleScale = 0.0
            }
        }
    }
    
    func triggerShareGlowAnimation() {
        withAnimation(.easeOut(duration: 0.4)) {
            shareGlowScale = 1.0
            shareGlowOpacity = 1.0
        }
        
        // Hide glow effect after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.shareGlowScale = 0.0
                self.shareGlowOpacity = 0.0
            }
        }
    }
    
    func updateAddButtonVisibility(isDragging: Bool) {
        if isDragging {
            addButtonOpacity = 0.0
            addButtonScale = 0.8
        } else {
            addButtonOpacity = 1.0
            addButtonScale = 1.0
        }
    }
}
