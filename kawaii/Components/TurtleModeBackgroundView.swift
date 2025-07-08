//
//  TurtleModeBackgroundView.swift
//  kawaii
//
//  Created by Amp on 7/7/25.
//

import SwiftUI

struct TurtleModeBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.9),
                Color.blue.opacity(0.7),
                Color.blue.opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)
        .overlay(
            // Optional: Add subtle pattern or texture
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .blendMode(.overlay)
                .ignoresSafeArea(.all)
        )
    }
}

#Preview {
    TurtleModeBackgroundView()
}
