//
//  bubuview.swift
//  kawaii
//
//  Created by ai on 8/11/25.
//

import SwiftUI

struct bubuview: View {
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Chain around neck area
                HStack(spacing: -10) {
                    ForEach(0..<8, id: \.self) { _ in
                        ChainLink(size: CGSize(width: 45, height: 30), wall: 6)
                            .rotationEffect(.degrees(Double.random(in: -15...15)))
                    }
                }
                .padding(.bottom, 20)
                
                // Face
                ZStack {
                    // Head (circle)
                    Circle()
                        .fill(Color(red: 0.95, green: 0.87, blue: 0.8))
                        .stroke(Color.black.opacity(0.1), lineWidth: 2)
                        .frame(width: 200, height: 200)
                    
                    VStack(spacing: 15) {
                        // Eyes
                        HStack(spacing: 40) {
                            // Left eye
                            Circle()
                                .fill(Color.black)
                                .frame(width: 15, height: 15)
                            
                            // Right eye
                            Circle()
                                .fill(Color.black)
                                .frame(width: 15, height: 15)
                        }
                        .offset(y: -20)
                        
                        // Nose (small triangle)
                        Triangle()
                            .fill(Color.pink.opacity(0.6))
                            .frame(width: 8, height: 6)
                            .offset(y: -10)
                        
                        // Mouth (arc)
                        Arc(startAngle: 0, endAngle: 180)
                            .stroke(Color.black.opacity(0.7), lineWidth: 3)
                            .frame(width: 30, height: 15)
                            .offset(y: -5)
                    }
                }
                
                // Neck area
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.87, blue: 0.8))
                    .frame(width: 60, height: 40)
                    .offset(y: -10)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

struct Arc: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
    }
}

#Preview {
    bubuview()
}