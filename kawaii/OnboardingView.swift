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
	@State private var showButton = false
	
	var body: some View {
		ZStack {
			// Background
			Color.black
				.ignoresSafeArea()
			
			// Video Player (no interactions)
			if let player = player {
				VideoPlayerView(player: player)
					.aspectRatio(contentMode: .fit)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.allowsHitTesting(false) // Disable all interactions
					.onAppear {
						// Auto-play when view appears
						player.play()
						
						// Show button after 5 seconds
						DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
							withAnimation(.easeInOut(duration: 0.5)) {
								showButton = true
							}
						}
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
			
			// Bottom Button (appears after 5 seconds)
			VStack {
				Spacer()
				
				if showButton {
					Button(action: {
						print("Allow full access for los clicked!")
					}) {
						Text("Allow full access 🥺")
							.font(.system(size: 27, weight: .regular))
							.foregroundColor(.black)
					}
					.buttonStyle(GlossyStartButtonStyle())
					.frame(maxWidth: .infinity)
					.padding(.bottom, 50) // Bottom spacing
					.transition(.move(edge: .bottom).combined(with: .opacity))
				}
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

// Custom video player view without native controls
struct VideoPlayerView: UIViewRepresentable {
	let player: AVPlayer
	
	func makeUIView(context: Context) -> PlayerView {
		let view = PlayerView()
		view.playerLayer.player = player
		view.playerLayer.videoGravity = .resizeAspect
		return view
	}
	
	func updateUIView(_ uiView: PlayerView, context: Context) {
		// Frame updates are handled automatically by PlayerView
	}
}

class PlayerView: UIView {
	override class var layerClass: AnyClass {
		return AVPlayerLayer.self
	}
	
	var playerLayer: AVPlayerLayer {
		return layer as! AVPlayerLayer
	}
}

#Preview {
	OnboardingView()
}
