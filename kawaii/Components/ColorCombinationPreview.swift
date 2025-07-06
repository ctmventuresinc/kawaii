//
//  ContentView.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI

struct ColorCombinationPreview: View {
    let colorCombinations: [(background: String, button: String, inviteButtonColor: String)] = [
        ("#4D9DE1", "#FF5C8D", "#FF5C8D"),
        ("#FF0095", "#FFEA00", "#FFEA00"),
        ("#F5F5F5", "#F03889", "#F03889"),
        ("#5500CC", "#FF0095", "#FF0095"),
        ("#E86A58", "#178E96", "#178E96"),
        ("#A8DADC", "#178E96", "#178E96"),
        ("#A8DADC", "#FBECCF", "#FBECCF"),
        ("#33A1FD", "#FA7921", "#FA7921"),
        ("#7DE0E6", "#FA7921", "#FA7921"),
        ("#7DE0E6", "#FF2A93", "#FF2A93"),
        ("#FF0095", "#77CC00", "#77CC00"),
        ("#F9F6F0", "#C19875", "#C19875"),
        ("#F70000", "#E447D1", "#E447D1")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Frame Color Combinations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                ForEach(0..<colorCombinations.count, id: \.self) { index in
                    let combo = colorCombinations[index]
                    
                    HStack(spacing: 20) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 30)
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(hex: combo.background))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                            Text("Background")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(hex: combo.button))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                            Text("Stroke")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(hex: combo.inviteButtonColor))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                            Text("Photo Filter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(combo.background)
                                .font(.caption)
                                .monospaced()
                            Text(combo.button)
                                .font(.caption)
                                .monospaced()
                            Text(combo.inviteButtonColor)
                                .font(.caption)
                                .monospaced()
                        }
                        .frame(width: 80)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ColorCombinationPreview()
}
