//
//  SoundManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import AVFoundation

@MainActor
class SoundService: ObservableObject {
    @Published var audioPlayer: AVAudioPlayer?
    @Published var backgroundAudioPlayer: AVAudioPlayer?
    @Published var currentImageName: String = ""
    @Published var showImageOverlay = false
    @Published var pulseScale: CGFloat = 1.0
    
    private let soundImagePairs: [SoundImagePair] = [
        SoundImagePair(soundName: "kawaii", imageName: "kawaii"),
        SoundImagePair(soundName: "saiyonara", imageName: "saiyonara"),
        SoundImagePair(soundName: "bombaclatt", imageName: "bombaclatt"),
        SoundImagePair(soundName: "nandeska", imageName: "nandeska")
    ]
    
    private let backgroundSounds = ["japan1", "japan2", "japan3", "boom"]
    
    func playMarioSuccessSound() {
        let randomPair = soundImagePairs.randomElement() ?? soundImagePairs[0]
        
        guard let path = Bundle.main.path(forResource: randomPair.soundName, ofType: "mp3") else {
            print("Could not find sound file: \(randomPair.soundName).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Configure audio session for mixing multiple sounds
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and store the main audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Play random background sound simultaneously
            playRandomBackgroundSound()
            
            // Show image overlay
            showImageOverlay(for: randomPair.imageName)
        } catch {
            print("Could not play sound: \(error)")
        }
    }
    
    private func playRandomBackgroundSound() {
        let randomBackgroundSound = backgroundSounds.randomElement() ?? backgroundSounds[0]
        
        guard let path = Bundle.main.path(forResource: randomBackgroundSound, ofType: "mp3") else {
            print("Could not find background sound file: \(randomBackgroundSound).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Create and store the background audio player
            backgroundAudioPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundAudioPlayer?.volume = 0.7 // Slightly lower volume for background
            backgroundAudioPlayer?.prepareToPlay()
            backgroundAudioPlayer?.play()
        } catch {
            print("Could not play background sound: \(error)")
        }
    }
    
    private func showImageOverlay(for imageName: String) {
        currentImageName = imageName
        showImageOverlay = true
        startPulsing()
        
        // Hide the image after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showImageOverlay = false
            self.pulseScale = 1.0 // Stop pulsing
            
            // Clear the image name after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentImageName = ""
            }
        }
    }
    
    private func startPulsing() {
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
    
    func playNandeskaSound() {
        guard let path = Bundle.main.path(forResource: "intro", ofType: "mp3") else {
            print("Could not find intro.mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not play intro sound: \(error)")
        }
    }
}
