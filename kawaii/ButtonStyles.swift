//
//  ButtonStyles.swift
//  kawaii
//
//  Created by Los Mayers on 6/22/25.
//

import SwiftUI

struct GlossyStartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color(red: 0.88, green: 0.92, blue: 0.96)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.cyan, lineWidth: 2)
                        )
                        .shadow(color: Color.gray.opacity(0.2), radius: 1, x: 0, y: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct LoadingGlossyButtonStyle: ButtonStyle {
    let isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(0.8)
            } else {
                configuration.label
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .frame(width: isLoading ? 60 : nil, height: 46)
        .padding(.horizontal, isLoading ? 0 : 40)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color(red: 0.88, green: 0.92, blue: 0.96)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.cyan, lineWidth: 2)
                    )
                    .shadow(color: Color.gray.opacity(0.2), radius: 1, x: 0, y: 1)
            }
        )
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLoading)
    }
}

struct GlossyEnvelopeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.gray)
            .frame(width: 90, height: 90)
            .background(
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.white, Color(red: 0.82, green: 0.86, blue: 0.90)]),
                            center: .center,
                            startRadius: 2,
                            endRadius: 60
                        )
                    )
                    .overlay(Circle().stroke(Color.cyan, lineWidth: 4))
                    .overlay(
                        Circle()
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 8)
                            .blur(radius: 6)
                    )
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.5)
                            .stroke(Color.white.opacity(0.6), lineWidth: 6)
                            .rotationEffect(.degrees(-45))
                            .blur(radius: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 2)
                            .blur(radius: 1)
                            .mask(
                                Circle().fill(
                                    LinearGradient(
                                        colors: [.black, .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                    )
                    .shadow(color: .gray.opacity(0.25), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
