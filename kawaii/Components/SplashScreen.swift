import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            // Background
            Color.clear
                .ignoresSafeArea()
            
            // Centered text
            VStack(spacing: 16) {
                Text("kawaii")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .opacity(0.9)
                
                Text("loading...")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

#Preview {
    SplashScreen()
        .background(Color.blue)
}
