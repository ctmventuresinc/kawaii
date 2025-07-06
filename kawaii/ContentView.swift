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


struct ContentView: View {
	@State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
	@State private var testing: Bool = false
	
	var body: some View {
		
		if testing {
			ColorCombinationPreview()
		} else {
			Group {
				switch authorizationStatus {
				case .authorized:
					RandomPhotoView()
				case .denied, .restricted, .limited:
					PermissionDeniedView()
				case .notDetermined:
					OnboardingView()
				@unknown default:
					OnboardingView()
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
