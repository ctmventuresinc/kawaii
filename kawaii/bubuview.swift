//
//  bubuview.swift
//  kawaii
//
//  Created by ai on 8/11/25.
//

import SwiftUI
import Foundation

struct BallChainBead: View {
    var body: some View {
        ZStack {
            // Main metal ball
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.75, green: 0.75, blue: 0.8),
                            Color(red: 0.9, green: 0.9, blue: 0.95),
                            Color(red: 0.6, green: 0.6, blue: 0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0.5, y: 0.5)
        }
    }
}

struct ConnectingWire: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.7, green: 0.7, blue: 0.75))
            .frame(width: 3, height: 1)
    }
}

struct bubuview: View {
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            // U-shaped ball chain
            GeometryReader { geometry in
                ForEach(0..<32, id: \.self) { index in
                    let t = Double(index) / 31.0 // 0 to 1
                    
                    // Create U shape: top left to bottom center to top right
                    let startX = geometry.size.width * 0.1  // 10% from left
                    let endX = geometry.size.width * 0.9    // 90% from left  
                    let topY = 50.0                         // Start from top of screen
                    let bottomY = geometry.size.height * 0.6 // Bottom of U
                    
                    // Quadratic bezier curve for U shape
                    let x = (1-t)*(1-t)*startX + 2*(1-t)*t*(geometry.size.width/2) + t*t*endX
                    let y = (1-t)*(1-t)*topY + 2*(1-t)*t*bottomY + t*t*topY
                    
                    ZStack {
                        // Connecting wire between beads
                        if index > 0 {
                            let prevT = Double(index - 1) / 31.0
                            let prevX = (1-prevT)*(1-prevT)*startX + 2*(1-prevT)*prevT*(geometry.size.width/2) + prevT*prevT*endX
                            let prevY = (1-prevT)*(1-prevT)*topY + 2*(1-prevT)*prevT*bottomY + prevT*prevT*topY
                            
                            let wireAngle = atan2(y - prevY, x - prevX) * 180 / .pi
                            let wireLength = sqrt((x - prevX) * (x - prevX) + (y - prevY) * (y - prevY))
                            
                            ConnectingWire()
                                .frame(width: wireLength, height: 1)
                                .rotationEffect(.degrees(wireAngle))
                                .position(x: (x + prevX) / 2, y: (y + prevY) / 2)
                        }
                        
                        // The bead
                        BallChainBead()
                            .position(x: x, y: y)
                    }
                }
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
