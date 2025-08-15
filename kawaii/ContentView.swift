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
import FirebaseRemoteConfig

enum AppMode {
	case testing
	case kawaiiapp
	case bubuapp
}

struct ContentView: View {
	@State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
	@State private var currentApp: AppMode?
	@State private var isConfigLoading: Bool = true
	
	var body: some View {
		Group {
			if isConfigLoading || currentApp == nil {
				ProgressView("Loading configuration…")
			} else {
				switch currentApp! {
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
					EmptyView()
				}
			}
		}
		.onAppear {
			fetchRemoteConfig()
		}
	}
	
	private func checkPhotoPermission() {
		authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
	}
	
	private func fetchRemoteConfig() {
		let remoteConfig = RemoteConfig.remoteConfig()
#if DEBUG
		let settings = RemoteConfigSettings()
		settings.minimumFetchInterval = 0
		remoteConfig.configSettings = settings
#endif
		remoteConfig.fetchAndActivate { status, error in
			DispatchQueue.main.async {
				let isBubu = remoteConfig.configValue(forKey: "bubucheck").boolValue
				self.currentApp = isBubu ? .bubuapp : .kawaiiapp
				self.isConfigLoading = false
			}
		}
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
