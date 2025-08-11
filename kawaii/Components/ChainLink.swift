//
//  ChainLink.swift
//  kawaii
//
//  Created by ai on 8/11/25.
//

import SwiftUI

struct ChainLink: View {
    let size: CGSize
    let wall: CGFloat
    
    var body: some View {
        Capsule()
            .stroke(
                LinearGradient(
                    colors: [Color.lightSilver, Color.white, Color.lightSilver, Color.gray.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: wall
            )
            .frame(width: size.width, height: size.height)
            .shadow(color: .black.opacity(0.2), radius: 3, x: 1, y: 2)
    }
}

extension Color {
    static let lightSilver = Color(red: 0.85, green: 0.85, blue: 0.9)
}

struct ConnectedChainLinks: View {
    var body: some View {
        ZStack {
            // First link - horizontal
            ChainLink(size: CGSize(width: 80, height: 50), wall: 10)
                .offset(x: -20)
            
            // Second link - vertical, interlocked
            ChainLink(size: CGSize(width: 80, height: 50), wall: 10)
                .rotationEffect(.degrees(90))
                .offset(x: 20)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        // Single link - more circular
        ChainLink(size: CGSize(width: 70, height: 50), wall: 12)
        
        // Connected links
        ConnectedChainLinks()
    }
    .padding()
}
