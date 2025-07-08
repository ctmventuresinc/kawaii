//
//  TurtleModeBackgroundView.swift
//  kawaii
//
//  Created by Amp on 7/7/25.
//

import SwiftUI

struct TurtleModeBackgroundView: View {
    @State private var mogImages: [MogImage] = []
    
    struct MogImage {
        let id = UUID()
        let imageName: String
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
        var isVisible: Bool = false
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.9),
                    Color.blue.opacity(0.7),
                    Color.blue.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            .overlay(
                // Optional: Add subtle pattern or texture
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .blendMode(.overlay)
                    .ignoresSafeArea(.all)
            )
            
            // Animated mog images
            ForEach(mogImages.filter(\.isVisible), id: \.id) { mog in
                Image(mog.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: mog.size, height: mog.size)
                    .offset(x: mog.x, y: mog.y)
                    .opacity(0.8)
                    .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0)
            }
        }
        .onAppear {
            generateMogImages()
            animateMogImages()
        }
    }
    
    private func generateMogImages() {
        let mogNames = ["mog1", "mog2", "mog3", "mog4", "mog5"]
        
        // Generate multiple instances of each mog image with progressive timing
        mogImages = (0..<15).map { index in
            let progress = Double(index) / 14.0  // 0 to 1
            let baseDelay = 0.3
            let maxDelay = 2.0
            // Exponential curve: slower at start, faster at end
            let delay = baseDelay + (maxDelay - baseDelay) * (1.0 - pow(progress, 2.0))
            
            return MogImage(
                imageName: mogNames[index % mogNames.count],
                x: CGFloat.random(in: -150...150),
                y: CGFloat.random(in: -250...250),
                size: CGFloat.random(in: 60...120),
                delay: delay
            )
        }
    }
    
    private func animateMogImages() {
        for (index, mog) in mogImages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + mog.delay) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    mogImages[index].isVisible = true
                }
            }
        }
    }
}

#Preview {
    TurtleModeBackgroundView()
}
