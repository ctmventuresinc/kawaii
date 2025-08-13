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
		Image("bigbubu")
			.resizable()
			.aspectRatio(contentMode: .fit)
			.scaleEffect(labubuScale)
		
	}
}

#Preview {
	bubuview()
}
