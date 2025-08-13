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
		GeometryReader { geo in
			let scale = geo.size.width / Asset.width
			let offsetBottom = (Asset.topHeight - Asset.overlap) * scale + bottomOffset
			let fullHeight = (Asset.topHeight + Asset.bottomHeight - Asset.overlap) * scale

			ZStack(alignment: .top) {
				// Bottom half underneath, positioned below the top half by the scaled offset
				Image("bigbubu_bottom")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.offset(y: offsetBottom)

				// Top half on top (drawn later ⇒ visually above)
				Image("bigbubu_top")
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
			.frame(width: geo.size.width, height: fullHeight, alignment: .top)
		}
		.scaleEffect(labubuScale)
	}
}

#Preview {
	bubuview()
}
