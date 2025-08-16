//
//  BubuSplashScreen.swift
//  kawaii
//
//  Created by AI on 8/16/25.
//

import SwiftUI

struct BubuSplashScreen: View {
    @State private var showBigStar = false
    @State private var showSmallStar = false
    @State private var randomStars: [RandomStar] = []
    
    struct RandomStar {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
        var isVisible: Bool = false
    }
    
    var body: some View {
        Group {
            ZStack {
                Image(.blankwallpaper)
                    .resizable()
                    .ignoresSafeArea()
                
                if showBigStar {
                    StarShapeView(size: 320)
                }
                
                if showSmallStar {
                    VStack {
                        Spacer()
                        HStack {
                            StarShapeView(size: 120)
                                .offset(x: -20, y: -50)
                            Spacer()
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.bottom, 40)
                }
                
                ForEach(randomStars.filter(\.isVisible), id: \.id) { star in
                    StarShapeView(size: star.size)
                        .offset(x: star.x, y: star.y)
                }
                
                // Absolutely centered app name
                Text("badbubu")
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
                randomStars = (0..<30).map { index in
                    let progress = Double(index) / 29.0
                    let baseDelay = 1.0
                    let maxDelay = 2.8
                    let delay = baseDelay + (maxDelay - baseDelay) * (1.0 - pow(progress, 2.5))
                    
                    return RandomStar(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300),
                        size: CGFloat.random(in: 30...100),
                        delay: delay
                    )
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showBigStar = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showSmallStar = true
                }
                
                for (index, star) in randomStars.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + star.delay) {
                        randomStars[index].isVisible = true
                    }
                }
            }
        }
    }
}

#Preview {
    BubuSplashScreen()
}


