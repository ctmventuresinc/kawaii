import SwiftUI

struct BallChainNecklaceView: View {
    let pendantScale: CGFloat = 1 // Easy scaling variable - 10x bigger for stress test
    @State private var swingAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // V/U-shaped ball chain
                ForEach(0..<60, id: \.self) { index in
                    let progress = Double(index) / 59.0
                    let x = progress * geometry.size.width
                    // Create proper U/V curve: both ends at y=0, bottom at chainDepth
                    let y = 4 * 120 * progress * (1 - progress) // Parabolic curve
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, Color.gray.opacity(0.3), Color.gray.opacity(0.8)],
                                center: .topLeading,
                                startRadius: 1,
                                endRadius: 3
                            )
                        )
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 0.3)
                        )
                        .position(x: x, y: y)
                }
                
                // Physics-based pendant attachment
                let chainLowestPoint = CGPoint(x: geometry.size.width/2, y: 120) // Lowest point of parabola
                let chainLength: CGFloat = 60
                let pendantAttachmentX = chainLowestPoint.x + sin(swingAngle * .pi / 180) * chainLength
                let pendantAttachmentY = chainLowestPoint.y + cos(swingAngle * .pi / 180) * chainLength
                
                // Purple connecting line from lowest chain point to pendant
                Path { path in
                    path.move(to: chainLowestPoint)
                    path.addLine(to: CGPoint(x: pendantAttachmentX, y: pendantAttachmentY))
                }
                .stroke(Color.purple.opacity(0.8), lineWidth: 2)
                
                // Large scalable pendant hanging from the line
                ZStack {
                    // Pendant shadow
                    Circle()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 120 * pendantScale + 4, height: 120 * pendantScale + 4)
                        .offset(x: 3, y: 3)
                    
                    // Main pendant
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, Color.pink.opacity(0.3), Color.pink.opacity(0.8)],
                                center: .topLeading,
                                startRadius: 15 * pendantScale,
                                endRadius: 50 * pendantScale
                            )
                        )
                        .frame(width: 120 * pendantScale, height: 120 * pendantScale)
                        .overlay(
                            Circle()
                                .stroke(Color.pink.opacity(0.6), lineWidth: 1.5)
                        )
                    
                    // Inner decorative element
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pink.opacity(0.2), Color.pink.opacity(0.6)],
                                center: .center,
                                startRadius: 8 * pendantScale,
                                endRadius: 20 * pendantScale
                            )
                        )
                        .frame(width: 40 * pendantScale, height: 40 * pendantScale)
                    
                    // Sparkle effect
                    ForEach(0..<8, id: \.self) { index in
                        Image(systemName: "sparkle")
                            .foregroundColor(.white)
                            .font(.system(size: 12 * pendantScale))
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 35 * pendantScale,
                                y: sin(Double(index) * .pi / 4) * 35 * pendantScale
                            )
                            .opacity(0.9)
                    }
                }
                .position(x: pendantAttachmentX, y: pendantAttachmentY + 60 * pendantScale)

            }
        }
        .clipped()
    }
}

#Preview {
    BallChainNecklaceView()
}
