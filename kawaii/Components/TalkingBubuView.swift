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

	// Original asset metrics (points)
	private enum Asset {
		static let width: CGFloat = 768
		static let topHeight: CGFloat = 1022
		static let bottomHeight: CGFloat = 850
		static let overlap: CGFloat = 362 // Amount top overhangs bottom
	}

	let labubuScale: CGFloat
	let isTalking: Bool
	
	var body: some View {
		Group {
			if isTalking {
				GeometryReader { geo in
					let scale = geo.size.width / Asset.width
					let offsetBottom = (Asset.topHeight - Asset.overlap) * scale + bottomOffset
					let fullHeight = (Asset.topHeight + Asset.bottomHeight - Asset.overlap) * scale

					ZStack(alignment: .top) {
						// Bottom half
						Image("bigbubu_bottom")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.offset(y: offsetBottom)

						// Top half
						Image("bigbubu_top")
							.resizable()
							.aspectRatio(contentMode: .fit)
					}
					.frame(width: geo.size.width, height: fullHeight, alignment: .top)
					// Enable tap to toggle mouth
					.contentShape(Rectangle())
					.onTapGesture {
						withAnimation(.easeInOut(duration: 0.25)) {
							mouthOpen.toggle()
							let jawDrop: CGFloat = 42 * scale // asset-space drop scaled to current width
							bottomOffset = mouthOpen ? jawDrop : 0
						}
					}
				}
			} else {
				Image("owlcutout")
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
		}
		.scaleEffect(labubuScale)
	}
}

#Preview {
	bubuview()
}
