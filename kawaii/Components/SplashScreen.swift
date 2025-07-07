//
//  SplashScreen.swift
//  kawaii
//
//  Created by Los Mayers on 7/6/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var bigStarOpacity: Double = 0
    @State private var smallStarOpacity: Double = 0
    
    var body: some View {
        Group {
            ZStack {
                
//                Color.clear
//                    .ignoresSafeArea()
				
				Image(.blankwallpaper)
					.resizable()
					.ignoresSafeArea()
                
                StarShapeView(size: 320)
                    .opacity(bigStarOpacity)
                
                // Small star behind release section
                VStack {
                    Spacer()
                    HStack {
                        StarShapeView(size: 120)
                            .offset(x: -20, y: -50)
                            .opacity(smallStarOpacity)
                        Spacer()
                    }
                }
                .padding(.leading, 10)
                .padding(.bottom, 40)
                
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
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    bigStarOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeIn(duration: 0.8)) {
                        smallStarOpacity = 1.0
                    }
                }
            }
        }
    }
}


#Preview {
    SplashScreen()
}
