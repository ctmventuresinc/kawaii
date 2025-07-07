import SwiftUI

struct StarShapeView: View {
    @State private var randomColorCombo = ColorCombinationsManager.shared.getRandomCombination()
    let size: CGFloat
    
    init(size: CGFloat = 320) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outermost stroke
            Image("harmonyshape")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size + 40, height: size + 40)
                .foregroundColor(Color(hex: randomColorCombo.combo.button))
                .shadow(color: Color(hex: randomColorCombo.combo.button).opacity(0.6), radius: 12, x: 0, y: 0)
            
            // Background shape
            Image("harmonyshape")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(Color(hex: randomColorCombo.combo.background))
                .shadow(color: Color(hex: randomColorCombo.combo.background).opacity(0.6), radius: 12, x: 0, y: 0)
        }
    }
}

#Preview {
    StarShapeView()
}
