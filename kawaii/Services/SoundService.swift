//
//  SoundManager.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import AVFoundation

enum SoundType {
    case intro
    case click
    case nandeska
    case loading
    case timetravel
    case custom(String)
    
    var fileName: String {
        switch self {
        case .intro:
            return "intro"
        case .click:
            return "click"
        case .nandeska:
            return "nandeska"
        case .loading:
            return "loading"
        case .timetravel:
            return "timetravel"
        case .custom(let name):
            return name
        }
    }
}

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
        SoundImagePair(soundName: "nandeska", imageName: "nandeska"),
		SoundImagePair(soundName: "kawaii", imageName: "gay"),
		SoundImagePair(soundName: "kawaii", imageName: "gay"),
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
    
    func playSound(_ soundType: SoundType, delay: TimeInterval = 0) {
        let fileName = soundType.fileName
        guard let path = Bundle.main.path(forResource: fileName, ofType: "mp3") else {
            print("Could not find \(fileName).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        let playAction = {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                print("Could not play \(fileName) sound: \(error)")
            }
        }
        
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playAction()
            }
        } else {
            playAction()
        }
    }
    
    func playLoadingSoundIfStillLoading(isLoadingCheck: @escaping () -> Bool, delay: TimeInterval = 0.7) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isLoadingCheck() {
                self.playSound(.loading)
            }
        }
    }
}
