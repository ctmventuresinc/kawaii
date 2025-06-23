//
//  ContentView.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
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
    
    private func checkPhotoPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
}

#Preview {
    ContentView()
}
