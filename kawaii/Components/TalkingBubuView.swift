//
//  TalkingBubuView.swift
//  kawaii
//
//  Created by Amp on 8/13/25.
//

import SwiftUI

struct TalkingBubuView: View {
    @State private var mouthOpen = false
    @State private var bottomOffset: CGFloat = 0
    let labubuScale: CGFloat
    let position: CGPoint
    let isTalking: Bool
    
    var body: some View {
        if isTalking {
            ZStack(alignment: .center) {
                VStack(spacing: -72 * labubuScale) {  // Scaled overlap spacing; we'll move bottom image instead
                    Image("bigbubu_top")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250 * labubuScale, height: 273 * labubuScale)
                        .zIndex(1)  // Bring top to front
                    
                    Image("bigbubu_bottom")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250 * labubuScale, height: 227 * labubuScale)
                        .offset(y: bottomOffset) // Move bottom lip down to open mouth
                        .zIndex(0)  // Keep bottom behind
                }
                
                Text("Recording...")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.red)
                    .opacity(mouthOpen ? 1 : 0)
                    .zIndex(1)
                    .offset(y: bottomOffset + 25 * labubuScale)

                // Animated recording waveform shown when mouth is open
                RecordingView()
                    .frame(width: 240 * labubuScale, height: 60 * labubuScale)
                    .opacity(mouthOpen ? 1 : 0)
                    .zIndex(-1)
                    // Always sit halfway between top and bottom images
                    .offset(y: bottomOffset - 25 * labubuScale)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    mouthOpen.toggle()
                    let openGap: CGFloat = 42 * labubuScale // distance the jaw should drop
                    bottomOffset = mouthOpen ? openGap : 0
                }
            }
            .position(position)
        } else {
            // Non-talking mode - single owl image
            ZStack(alignment: .center) {
                Image("owlcutout")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250 * labubuScale, height: 250 * labubuScale)
            }
            .position(position)
        }
    }
}

#Preview {
	bubuview()
}
