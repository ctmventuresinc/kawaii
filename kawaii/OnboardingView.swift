//
//  OnboardingView.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import SwiftUI
import AVKit
import AVFoundation
import Photos
import OneSignalFramework

struct OnboardingView: View {
	@State private var player: AVPlayer?
	@State private var showButton = false
	@State private var blinkingText = "this is your life"
	@State private var blinkingOpacity: Double = 0.0
	@State private var textOpacity: Double = 1.0
	@State private var showPermissionDenied = false
	
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
			
			// Cycling text at top
			VStack {
				Text(blinkingText)
					.font(.system(size: 19, weight: .regular))
					.foregroundColor(Color.gray.opacity(0.7))
					.opacity(textOpacity)
					.animation(.easeInOut(duration: 0.65), value: textOpacity)
					.padding(.top, 50)
				
				Spacer()
			}
			
			// Bottom Button (appears after 5 seconds)
			VStack {
				Spacer()
				
				if showButton {
					Button(action: {
						requestPhotoPermission()
					}) {
						Text("Allow full access for los 🥀🥺")
							.font(.system(size: 27, weight: .semibold))
							.foregroundColor(.black)
					}
					.buttonStyle(GlossyStartButtonStyle())
					.frame(height: 90)
					.frame(maxWidth: .infinity)
					.padding(.horizontal, 8)
					.padding(.bottom, 50)
					.transition(.move(edge: .bottom).combined(with: .opacity))
				}
			}
		}
		.fullScreenCover(isPresented: $showPermissionDenied) {
			PermissionDeniedView()
		}
		.onAppear {
			setupPlayer()
			startTextCycle()
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
	
	private func startTextCycle() {
		let possibleTexts = AppConstants.cyclingTexts
		
		Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
			// Fade out
			withAnimation(.easeInOut(duration: 0.65)) {
				textOpacity = 0.0
			}
			
			// Change text and fade back in
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
				blinkingText = possibleTexts.randomElement() ?? "this is your life"
				withAnimation(.easeInOut(duration: 0.65)) {
					textOpacity = 1.0
				}
			}
		}
	}
	
	private func requestPhotoPermission() {
		PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
			DispatchQueue.main.async {
				switch status {
				case .authorized:
					// Full access granted - notification request will happen on first screen tap
					break
				case .denied, .restricted, .limited:
					// Permission denied or limited - show red error screen
					showPermissionDenied = true
				case .notDetermined:
					// This shouldn't happen after request, but handle it
					break
				@unknown default:
					break
				}
			}
		}
	}
	
	private func requestNotificationPermission() {
		OneSignal.Notifications.requestPermission({ accepted in
			print("User accepted notifications: \(accepted)")
			// Navigation will be handled by ContentView observing the change
		}, fallbackToSettings: false)
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
