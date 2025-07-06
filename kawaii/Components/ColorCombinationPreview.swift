//
//  ContentView.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI

enum ColorType {
    case background, stroke, photoFilter
}

struct ColorCombinationPreview: View {
    @State private var selectedCombination: Int? = nil
    @State private var samplePhotoItem: SamplePhotoItem? = nil
    @State private var showToast = false
    
    @ObservedObject private var colorManager = ColorCombinationsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Top half - scrollable color combinations
            VStack(spacing: 8) {
                Text("Frame Color Combinations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(0..<colorManager.colorCombinations.count, id: \.self) { index in
                            let combo = colorManager.colorCombinations[index]
                            
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .frame(width: 25)
                                
                                VStack(spacing: 2) {
                                    ColorPicker("", selection: Binding(
                                        get: { Color(hex: combo.background) },
                                        set: { newColor in
                                            colorManager.colorCombinations[index].background = newColor.toHex()
                                            if selectedCombination == index {
                                                createSamplePhotoItem(for: index)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .frame(width: 60, height: 40)
                                    Text("Bground")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    ColorPicker("", selection: Binding(
                                        get: { Color(hex: combo.button) },
                                        set: { newColor in
                                            colorManager.colorCombinations[index].button = newColor.toHex()
                                            if selectedCombination == index {
                                                createSamplePhotoItem(for: index)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .frame(width: 60, height: 40)
                                    Text("Stroke")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    ColorPicker("", selection: Binding(
                                        get: { Color(hex: combo.inviteButtonColor) },
                                        set: { newColor in
                                            colorManager.colorCombinations[index].inviteButtonColor = newColor.toHex()
                                            if selectedCombination == index {
                                                createSamplePhotoItem(for: index)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .frame(width: 60, height: 40)
                                    Text("Filter")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    Text(combo.background)
                                        .font(.caption2)
                                        .monospaced()
                                    Text(combo.button)
                                        .font(.caption2)
                                        .monospaced()
                                    Text(combo.inviteButtonColor)
                                        .font(.caption2)
                                        .monospaced()
                                }
                                .frame(width: 70)
                                .onTapGesture {
                                    let hexString = "\(combo.background), \(combo.button), \(combo.inviteButtonColor)"
                                    UIPasteboard.general.string = hexString
                                    showToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        showToast = false
                                    }
                                }
                                
                                Button(action: {
                                    selectedCombination = index
                                    createSamplePhotoItem(for: index)
                                }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "eye")
                                            .font(.title3)
                                        Text("Preview")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.blue)
                                    .frame(width: 50, height: 40)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Bottom half - always visible preview
            VStack {
                Divider()
                
                if let samplePhotoItem = samplePhotoItem {
                    VStack(spacing: 12) {
                        Text("Combination \(selectedCombination! + 1) Preview")
                            .font(.headline)
                        
                        SampleFramedPhotoView(photoItem: samplePhotoItem)
                            .frame(width: 180, height: 180)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Tap a combination to preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .frame(height: 250)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
        }
        .overlay(
            Group {
                if showToast {
                    Text("Copied")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showToast),
            alignment: .bottom
        )
    }
    
    private func createSamplePhotoItem(for combinationIndex: Int) {
        let sampleImage = createSampleImage()
        let combo = colorManager.colorCombinations[combinationIndex]
        
        // Create a sample PhotoItem with custom colors
        let photoItem = SamplePhotoItem(
            image: sampleImage,
            backgroundColor: Color(hex: combo.background),
            strokeColor: Color(hex: combo.button),
            photoFilter: .customColor(combo.inviteButtonColor)
        )
        
        self.samplePhotoItem = photoItem
    }
    
    private func createSampleImage() -> UIImage {
        // Use the actual cutoutpngfreya asset from the app
        return UIImage(named: "cutoutpngfreya") ?? UIImage()
    }
    

}

// Sample PhotoItem for preview purposes  
struct SamplePhotoItem {
    let id = UUID()
    let image: UIImage
    let position: CGPoint = .zero
    let dragOffset: CGSize = .zero
    let isDragging: Bool = false
    let scale: CGFloat = 1.0
    let frameShape: FaceFrameShape? = .irregularBurst
    let size: CGFloat = 150
    let strokeColor: Color
    let backgroundColor: Color
    let burstShape: IrregularBurstShape? = IrregularBurstShape()
    let shapeName: String = "harmonyshape"
    let photoFilter: PhotoFilter
    
    init(image: UIImage, backgroundColor: Color, strokeColor: Color, photoFilter: PhotoFilter) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.photoFilter = photoFilter
    }
}

// Sample FramedPhotoView for previews
struct SampleFramedPhotoView: View {
    let photoItem: SamplePhotoItem
    
    var body: some View {
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



#Preview {
    ColorCombinationPreview()
}
