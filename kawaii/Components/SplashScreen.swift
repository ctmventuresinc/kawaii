//
//  SplashScreen.swift
//  kawaii
//
//  Created by Los Mayers on 7/6/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var randomColorCombo = ColorCombinationsManager.shared.getRandomCombination()
    
    var body: some View {
        Group {
            ZStack {
                
//                Color.clear
//                    .ignoresSafeArea()
				
				Image(.blankwallpaper)
					.resizable()
					.ignoresSafeArea()
                
                // Framed star background
                ZStack {
                    // Outermost stroke
                    Image("harmonyshape")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 360, height: 360)
                        .foregroundColor(Color(hex: randomColorCombo.combo.button))
                        .shadow(color: Color(hex: randomColorCombo.combo.button).opacity(0.6), radius: 12, x: 0, y: 0)
                    
                    // Background shape
                    Image("harmonyshape")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320, height: 320)
                        .foregroundColor(Color(hex: randomColorCombo.combo.background))
                        .shadow(color: Color(hex: randomColorCombo.combo.background).opacity(0.6), radius: 12, x: 0, y: 0)
                }
                
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
