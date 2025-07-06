//
//  ContentView.swift
//  kawaii
//
//  Created by Los Mayers on 6/18/25.
//

import SwiftUI

struct ColorCombinationPreview: View {
    @State private var selectedCombination: Int? = nil
    @State private var samplePhotoItem: SamplePhotoItem? = nil
    
    let colorCombinations: [(background: String, button: String, inviteButtonColor: String)] = [
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
        ScrollView {
            VStack(spacing: 16) {
                Text("Frame Color Combinations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                ForEach(0..<colorCombinations.count, id: \.self) { index in
                    let combo = colorCombinations[index]
                    
                    HStack(spacing: 20) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 30)
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(hex: combo.background))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                            Text("Background")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(hex: combo.button))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                            Text("Stroke")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(hex: combo.inviteButtonColor))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                            Text("Photo Filter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(combo.background)
                                .font(.caption)
                                .monospaced()
                            Text(combo.button)
                                .font(.caption)
                                .monospaced()
                            Text(combo.inviteButtonColor)
                                .font(.caption)
                                .monospaced()
                        }
                        .frame(width: 80)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Tapped combination \(index + 1)")
                        selectedCombination = index
                        createSamplePhotoItem(for: index)
                    }
                    
                    Divider()
                }
                
                // Show sample frame if one is selected
                if let samplePhotoItem = samplePhotoItem {
                    VStack(spacing: 16) {
                        Text("Frame Preview - Combination \(selectedCombination! + 1)")
                            .font(.headline)
                        
                        SampleFramedPhotoView(photoItem: samplePhotoItem)
                            .frame(width: 200, height: 200)
                        
                        Button("Close Preview") {
                            selectedCombination = nil
                            self.samplePhotoItem = nil
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
    
    private func createSamplePhotoItem(for combinationIndex: Int) {
        print("Creating sample for combination \(combinationIndex + 1)")
        let sampleImage = createSampleImage()
        let combo = colorCombinations[combinationIndex]
        
        // Create a sample PhotoItem with custom colors
        let photoItem = SamplePhotoItem(
            image: sampleImage,
            backgroundColor: Color(hex: combo.background),
            strokeColor: Color(hex: combo.button),
            photoFilter: .customColor(combo.inviteButtonColor)
        )
        
        print("Setting samplePhotoItem...")
        self.samplePhotoItem = photoItem
        print("samplePhotoItem set: \(self.samplePhotoItem != nil)")
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
