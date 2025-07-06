//
//  SplashScreen.swift
//  kawaii
//
//  Created by Los Mayers on 7/6/25.
//

import SwiftUI

struct SplashScreen: View {
    
    var body: some View {
        Group {
            ZStack {
                
//                Color.clear
//                    .ignoresSafeArea()
				
				Image(.blankwallpaper)
					.resizable()
					.ignoresSafeArea()
                
                // Absolutely centered "kawaii" text
                Text("kawaii")
                    .font(.system(size: 48, weight: .bold))
					.foregroundColor(.black)
                    
                
                // Bottom content
                VStack {
                    Spacer()
                    
                    // Build section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("build")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.black)
                        Text("los, bunny, marc, mihir")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Release section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("release")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.black)
                        Text("danger testing")
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(40)
            }
        }
    }
}


#Preview {
    SplashScreen()
}
