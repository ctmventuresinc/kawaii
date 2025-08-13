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
    let isTalking: Bool
    
    var body: some View {
        if isTalking {
            ZStack(alignment: .center) {
                VStack(spacing: -72) {  // overlap spacing in unscaled points
                    Image("bigbubu_top")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .zIndex(1)
                    Image("bigbubu_bottom")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .offset(y: bottomOffset)
                        .zIndex(0)
                }

                Text("Recording...")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.red)
                    .opacity(mouthOpen ? 1 : 0)
                    .zIndex(1)
                    .offset(y: bottomOffset + 25)

                RecordingView()
                    .frame(width: 240, height: 60)
                    .opacity(mouthOpen ? 1 : 0)
                    .zIndex(-1)
                    .offset(y: bottomOffset - 25)
            }
            .scaleEffect(labubuScale)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    mouthOpen.toggle()
                    let openGap: CGFloat = 42 // in unscaled points
                    bottomOffset = mouthOpen ? openGap : 0
                }
            }
        } else {
            Image("bigbubu")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(labubuScale)
        }
    }
}

#Preview {
    bubuview()
}
