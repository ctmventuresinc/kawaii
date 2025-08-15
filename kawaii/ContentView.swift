//
//  ContentView.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI
import Photos
import UserNotifications
import OneSignalFramework

enum AppMode {
	case testing
	case kawaiiapp
	case bubuapp
}

struct ContentView: View {
	@State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
	@State private var currentApp: AppMode = .testing
	
	var body: some View {
		
		switch currentApp {
		case .testing:
			bubuview()
		case .bubuapp:
			// Add bubuapp view here
			Text("BubuApp Coming Soon")
				.font(.title)
				.foregroundColor(.purple)
		case .kawaiiapp:
			Group {
				switch authorizationStatus {
				case .authorized:
					RandomPhotoView()
				case .denied, .restricted, .limited:
					PermissionDeniedView()
				case .notDetermined:
					KawaiiOnboardingView()
				@unknown default:
					KawaiiOnboardingView()
				}
			}
			.onAppear {
				checkPhotoPermission()
			}
			.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
				// Check permission when app becomes active (user might have changed settings)
				checkPhotoPermission()
			}
		}
		
	}
	
	private func checkPhotoPermission() {
		authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
	}
}

#Preview {
	ContentView()
}


/*
 
 2. none
 8. none
 11. none
 13. none
 
 */
