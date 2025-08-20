//
//  ContentView.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI
import Photos
import UserNotifications
// import OneSignalFramework
import FirebaseRemoteConfig

enum AppMode {
	case testing
	case kawaiiapp
	case bubuapp
}

struct ContentView: View {
	@State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
	@State private var currentApp: AppMode?
	@State private var hasBubuAccess = false
	@ObservedObject private var rcStore = RemoteConfigStore.shared
	
	var body: some View {
		Group {
			if !rcStore.isLoaded && !FeatureFlags.shared.testing {
				VStack{
					Text("Loading")
					ProgressView("Loading configuration…")
				}
			} else if let current = currentApp {
				switch current {
				case .bubuapp:
					bubuview()
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
						checkPhotoPermission()
					}
				case .testing:
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
						checkPhotoPermission()
					}
				}
			} else {
				ProgressView()
			}
		}
		.onAppear {
			if FeatureFlags.shared.testing {
				currentApp = .testing
				return
			}
			if !rcStore.isLoaded {
				rcStore.refresh()
			}
			// determine app once store updates
			currentApp = rcStore.bubuEnabled ? .bubuapp : .kawaiiapp
		}
		.onReceive(rcStore.$bubuEnabled) { value in
			if FeatureFlags.shared.testing {
				currentApp = .testing
			} else {
				currentApp = value ? .bubuapp : .kawaiiapp
			}
		}
	}
	
	private func checkPhotoPermission() {
		authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
	}
	
	// removed local fetchRemoteConfig (now using RemoteConfigStore)
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
