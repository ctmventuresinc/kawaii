//
//  ShareManager.swift
//  kawaii
//

import SwiftUI
import UIKit

@MainActor
class ShareManager: ObservableObject {
    @Published var areButtonsHidden = false
    
    private let shareService: ShareService
    private let soundService: SoundService
    
    init(shareService: ShareService, soundService: SoundService) {
        self.shareService = shareService
        self.soundService = soundService
    }
    
    func shareScreenshot() {
        soundService.playSound(.click)
        
        // Hide all buttons with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            areButtonsHidden = true
        }
        
        // Capture screenshot on background queue after animation
        Task {
            // Wait for animation to complete
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Capture screenshot on background queue
            let screenshot = await captureScreenshot()
            
            await MainActor.run {
                if let screenshot = screenshot {
                    // Create share items with cute text and TestFlight link
                    let shareText = "this is so cute https://apps.apple.com/us/app/id6747457695"
                    shareService.shareImage = screenshot
                    shareService.shareText = shareText
                    shareService.showShareSheet = true
                }
                
                // Unhide buttons after short delay
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            areButtonsHidden = false
                        }
                    }
                }
            }
        }
    }
    
    private func captureScreenshot() async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
                    let screenshot = renderer.image { _ in
                        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                    }
                    continuation.resume(returning: screenshot)
                }
            }
        }
    }
}
