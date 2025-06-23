//
//  ViewComponents.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

// Burst pattern background
struct BurstPatternBackground: View {
    let rotationAngle: Double
    
    // White and orange colors
    private let colorSets: [[Color]] = [
        [Color.white, Color.orange]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let maxRadius = max(geometry.size.width, geometry.size.height) * 0.8
            let numberOfRays = 24
            
            ZStack {
                // Background color
                Color.black.ignoresSafeArea()
                
                ForEach(0..<numberOfRays, id: \.self) { index in
                    let angle = Double(index) * (360.0 / Double(numberOfRays))
                    let colorSetIndex = index % colorSets.count
                    let colorIndex = (index / colorSets.count) % colorSets[colorSetIndex].count
                    let rayColor = colorSets[colorSetIndex][colorIndex]
                    
                    // Create each ray as a triangle
                    Path { path in
                        let radianAngle = CGFloat(angle + rotationAngle) * .pi / 180.0
                        let rayWidth: CGFloat = 20.0
                        
                        // Center point
                        path.move(to: CGPoint(x: centerX, y: centerY))
                        
                        // Left edge of ray
                        let leftAngle = radianAngle - (rayWidth * .pi / 180.0) / 2.0
                        path.addLine(to: CGPoint(
                            x: centerX + cos(leftAngle) * maxRadius,
                            y: centerY + sin(leftAngle) * maxRadius
                        ))
                        
                        // Right edge of ray
                        let rightAngle = radianAngle + (rayWidth * .pi / 180.0) / 2.0
                        path.addLine(to: CGPoint(
                            x: centerX + cos(rightAngle) * maxRadius,
                            y: centerY + sin(rightAngle) * maxRadius
                        ))
                        
                        path.closeSubpath()
                    }
                    .fill(rayColor)
                }
            }
        }
    }
}
