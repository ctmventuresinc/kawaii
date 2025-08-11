import SwiftUI

struct CounselView: View {
    let linkCount: Int
    let linkSize: CGSize
    let chainRadius: CGFloat
    @State private var rotationAngle: Double = 0
    
    init(linkCount: Int = 40, linkSize: CGSize = CGSize(width: 25, height: 35), chainRadius: CGFloat = 150) {
        self.linkCount = linkCount
        self.linkSize = linkSize
        self.chainRadius = chainRadius
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<linkCount, id: \.self) { index in
                    ChainLinkView(
                        size: linkSize,
                        isAlternate: index % 2 == 1
                    )
                    .position(
                        x: geometry.size.width / 2 + chainRadius * cos(angle(for: index)),
                        y: geometry.size.height / 2 + chainRadius * sin(angle(for: index))
                    )
                    .rotationEffect(.degrees(linkRotationAngle(for: index)))
                }
            }
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func angle(for index: Int) -> Double {
        let angleStep = 2 * .pi / Double(linkCount)
        return Double(index) * angleStep - .pi / 2 // Start from top
    }
    
    private func linkRotationAngle(for index: Int) -> Double {
        let baseAngle = angle(for: index) * 180 / .pi + 90
        return baseAngle + (index % 2 == 1 ? 90 : 0) // Alternate link rotation
    }
}

struct ChainLinkView: View {
    let size: CGSize
    let isAlternate: Bool
    
    var body: some View {
        ZStack {
            // Outer oval (shadow/depth)
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.black.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width + 2, height: size.height + 2)
            
            // Main link
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.gray.opacity(0.7), Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width, height: size.height)
            
            // Inner hole
            Ellipse()
                .fill(Color.clear)
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.4), Color.black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size.width * 0.6, height: size.height * 0.6)
            
            // Highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.8), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: min(size.width, size.height) * 0.3
                    )
                )
                .frame(width: size.width * 0.4, height: size.height * 0.4)
                .offset(x: -size.width * 0.15, y: -size.height * 0.15)
        }
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }
}

struct ChainView_Previews: PreviewProvider {
    static var previews: some View {
        CounselView()
            .padding()
    }
}
