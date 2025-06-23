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
            Color.red
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Error message or branding could go here
                Text("📸")
                    .font(.system(size: 80))
                
                Spacer()
                
                // Button to open settings
                Button(action: {
                    openAppSettings()
                }) {
                    Text("allow full access for the danger boy band")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(GlossyStartButtonStyle())
                .frame(height: 60)
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
