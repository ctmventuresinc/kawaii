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
    @State private var showingColorPicker = false
    @State private var editingColorType: ColorType? = nil
    @State private var editingCombinationIndex: Int? = nil
    @State private var tempColor: Color = .white
    
    @State private var colorCombinations: [(background: String, button: String, inviteButtonColor: String)] = [
        ("#4D9DE1", "#FF5C8D", "#FF5C8D"),
        ("#FF0095", "#FFEA00", "#FFEA00"),
        ("#F5F5F5", "#F03889", "#F03889"),
        ("#5500CC", "#FF0095", "#FF0095"),
        ("#E86A58", "#178E96", "#178E96"),
        ("#A8DADC", "#178E96", "#178E96"),
        ("#A8DADC", "#FBECCF", "#FBECCF"),
        ("#33A1FD", "#FA7921", "#FA7921"),
        ("#7DE0E6", "#FA7921", "#FA7921"),
        ("#7DE0E6", "#FF2A93", "#FF2A93"),
        ("#FF0095", "#77CC00", "#77CC00"),
        ("#F9F6F0", "#C19875", "#C19875"),
        ("#F70000", "#E447D1", "#E447D1")
    ]
    
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
                        ForEach(0..<colorCombinations.count, id: \.self) { index in
                            let combo = colorCombinations[index]
                            
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .frame(width: 25)
                                
                                VStack(spacing: 2) {
                                    ColorPicker("", selection: Binding(
                                        get: { Color(hex: combo.background) },
                                        set: { newColor in
                                            colorCombinations[index].background = newColor.toHex()
                                            if selectedCombination == index {
                                                createSamplePhotoItem(for: index)
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .frame(width: 60, height: 40)
                                    Text("Background")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    ColorPicker("", selection: Binding(
                                        get: { Color(hex: combo.button) },
                                        set: { newColor in
                                            colorCombinations[index].button = newColor.toHex()
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
                                            colorCombinations[index].inviteButtonColor = newColor.toHex()
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
    }
    
    private func createSamplePhotoItem(for combinationIndex: Int) {
        let sampleImage = createSampleImage()
        let combo = colorCombinations[combinationIndex]
        
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
    
    private func updateColor(_ newColor: Color) {
        guard let combinationIndex = editingCombinationIndex,
              let colorType = editingColorType else { return }
        
        let hexString = newColor.toHex()
        
        switch colorType {
        case .background:
            colorCombinations[combinationIndex].background = hexString
        case .stroke:
            colorCombinations[combinationIndex].button = hexString
        case .photoFilter:
            colorCombinations[combinationIndex].inviteButtonColor = hexString
        }
        
        // Update preview if this combination is currently selected
        if selectedCombination == combinationIndex {
            createSamplePhotoItem(for: combinationIndex)
        }
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
