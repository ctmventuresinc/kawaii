//
//  TestBuViewq.swift
//  kawaii
//
//  Created by Los Mayers on 8/12/25.
//

import SwiftUI

struct TestBuViewq: View {
    var body: some View {
		VStack(spacing: 0) {
				Image("bigbubu_top")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 250, height: 250)
				
				Image("bigbubu_bottom")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 250, height: 250)
			}
    }
}

#Preview {
    TestBuViewq()
}
