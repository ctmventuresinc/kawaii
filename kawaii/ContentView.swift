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
    @State private var notificationPermissionAnswered = false
    
    var body: some View {
        Group {
            switch authorizationStatus {
            case .authorized:
                if notificationPermissionAnswered {
                    RandomPhotoView()
                } else {
                    OnboardingView()
                }
            case .denied, .restricted, .limited:
                PermissionDeniedView()
            case .notDetermined:
                OnboardingView()
            @unknown default:
                OnboardingView()
            }
        }
        .onAppear {
            checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check permissions when app becomes active (user might have changed settings)
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        checkNotificationPermission()
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionAnswered = settings.authorizationStatus != .notDetermined
            }
        }
    }
}

#Preview {
    ContentView()
}
