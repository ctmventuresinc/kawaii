//
//  PermissionDeniedView.swift
//  kawaii
//
//  Created by AI Assistant on 6/23/25.
//

import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        ZStack {
            // Full red background
			Color.purple
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Middle text message
                Text("Allow full access to your photos so the app can create a personalized collage using images from your library.")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Button to open settings
                Button(action: {
                    openAppSettings()
                }) {
                    Text("allow full access")
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundColor(.black)
                }
                .buttonStyle(GlossyStartButtonStyle())
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    PermissionDeniedView()
}
