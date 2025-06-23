//
//  OnboardingView.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import SwiftUI
import AVKit
import AVFoundation

struct OnboardingView: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Video Player
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        // Auto-play when view appears
                        player.play()
                    }
                    .onDisappear {
                        // Pause when view disappears
                        player.pause()
                    }
            } else {
                // Loading state
                ProgressView("Loading...")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "losintro", withExtension: "MOV") else {
            print("Could not find losintro.MOV in bundle")
            return
        }
        
        player = AVPlayer(url: videoURL)
        
        // Configure for auto-play
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        // Loop video (optional)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

#Preview {
    OnboardingView()
}
