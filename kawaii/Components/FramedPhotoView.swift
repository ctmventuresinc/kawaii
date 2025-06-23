//
//  FramedPhotoView.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI

// Framed photo view component
struct FramedPhotoView: View {
    let photoItem: PhotoItem
    
    var body: some View {
        if let frameShape = photoItem.frameShape {
            // Face crops with exciting frames
            switch frameShape {
            case .irregularBurst:
                ZStack {
                    // Outermost stroke using color combination
                    Image(photoItem.shapeName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: photoItem.size + 160, height: photoItem.size + 160)
                        .foregroundColor(photoItem.strokeColor)
                        .shadow(color: photoItem.strokeColor.opacity(0.6), radius: 12, x: 0, y: 0)
                    
                    // Background shape using color combination
                    Image(photoItem.shapeName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: photoItem.size + 120, height: photoItem.size + 120)
                        .foregroundColor(photoItem.backgroundColor)
                        .shadow(color: photoItem.backgroundColor.opacity(0.6), radius: 12, x: 0, y: 0)
                    
                    // Photo on top - masked by outer stroke shape with color filter
                    Image(uiImage: photoItem.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: photoItem.size, height: photoItem.size)
                        .applyPhotoFilter(photoItem.photoFilter)
                        .mask(
                            Image(photoItem.shapeName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: photoItem.size + 160, height: photoItem.size + 160)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
}
