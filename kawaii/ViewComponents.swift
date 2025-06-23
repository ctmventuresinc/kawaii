//
//  ViewComponents.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import UIKit

// Drag interaction manager to handle all photo drag states and actions
@MainActor
class DragInteractionManager: ObservableObject {
    @Published var isDraggingAny = false
    @Published var isHoveringOverTrash = false
    @Published var isHoveringOverStar = false
    @Published var isHoveringOverShare = false
    @Published var trashBinOpacity: Double = 0.0
    @Published var trashBinScale: CGFloat = 1.0
    @Published var starButtonOpacity: Double = 0.0
    @Published var starButtonScale: CGFloat = 1.0
    @Published var shareButtonOpacity: Double = 0.0
    @Published var shareButtonScale: CGFloat = 1.0
    
    // Action closures
    var isOverTrashBin: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var isOverShareButton: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var isOverStarButton: ((CGPoint, PhotoItem, GeometryProxy) -> Bool)?
    var deletePhotoItem: ((Int) -> Void)?
    var sharePhotoItem: ((PhotoItem) -> Void)?
    var convertToFramedPhoto: ((Int) -> Void)?
    
    func updateDragStates(isDragging: Bool) {
        if isDragging {
            trashBinOpacity = 1.0
            trashBinScale = 1.0
            starButtonOpacity = 1.0
            starButtonScale = 1.0
            shareButtonOpacity = 1.0
            shareButtonScale = 1.0
        } else {
            trashBinOpacity = 0.0
            trashBinScale = 0.8
            starButtonOpacity = 0.0
            starButtonScale = 0.8
            shareButtonOpacity = 0.0
            shareButtonScale = 0.8
        }
    }
    
    func resetDragStates() {
        isDraggingAny = false
        isHoveringOverTrash = false
        isHoveringOverStar = false
        isHoveringOverShare = false
    }
}

// Burst pattern background
struct BurstPatternBackground: View {
    let rotationAngle: Double
    
    // White and orange colors
    private let colorSets: [[Color]] = [
        [Color.white, Color.orange]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let maxRadius = max(geometry.size.width, geometry.size.height) * 0.8
            let numberOfRays = 24
            
            ZStack {
                // Background color
                Color.black.ignoresSafeArea()
                
                ForEach(0..<numberOfRays, id: \.self) { index in
                    let angle = Double(index) * (360.0 / Double(numberOfRays))
                    let colorSetIndex = index % colorSets.count
                    let colorIndex = (index / colorSets.count) % colorSets[colorSetIndex].count
                    let rayColor = colorSets[colorSetIndex][colorIndex]
                    
                    // Create each ray as a triangle
                    Path { path in
                        let radianAngle = CGFloat(angle + rotationAngle) * .pi / 180.0
                        let rayWidth: CGFloat = 20.0
                        
                        // Center point
                        path.move(to: CGPoint(x: centerX, y: centerY))
                        
                        // Left edge of ray
                        let leftAngle = radianAngle - (rayWidth * .pi / 180.0) / 2.0
                        path.addLine(to: CGPoint(
                            x: centerX + cos(leftAngle) * maxRadius,
                            y: centerY + sin(leftAngle) * maxRadius
                        ))
                        
                        // Right edge of ray
                        let rightAngle = radianAngle + (rayWidth * .pi / 180.0) / 2.0
                        path.addLine(to: CGPoint(
                            x: centerX + cos(rightAngle) * maxRadius,
                            y: centerY + sin(rightAngle) * maxRadius
                        ))
                        
                        path.closeSubpath()
                    }
                    .fill(rayColor)
                }
            }
        }
    }
}

// Activity view for sharing
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Loading overlay component
struct LoadingOverlay: View {
    let isLoading: Bool
    let text: String
    
    init(isLoading: Bool, text: String = "Adding photo...") {
        self.isLoading = isLoading
        self.text = text
    }
    
    var body: some View {
        if isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
                    .blur(radius: 1)
            )
            .scaleEffect(isLoading ? 1.0 : 0.8)
            .opacity(isLoading ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
        }
    }
}

// Sound image overlay component
struct SoundImageOverlay: View {
    let showOverlay: Bool
    let imageName: String
    let pulseScale: CGFloat
    
    var body: some View {
        if showOverlay && !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                .shadow(color: .pink.opacity(0.8), radius: 20, x: 0, y: 0)
                .scaleEffect((showOverlay ? 1.2 : 0.1) * pulseScale)
                .opacity(showOverlay ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.2), value: showOverlay)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseScale)
        }
    }
}

// Photo item view component
struct PhotoItemView: View {
    let photoItem: PhotoItem
    let geometry: GeometryProxy
    @Binding var photoItems: [PhotoItem]
    @ObservedObject var dragManager: DragInteractionManager
    
    var body: some View {
        Group {
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
            } else {
                // Regular photos with rounded corners
                Image(uiImage: photoItem.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: photoItem.size, height: photoItem.size)
                    .cornerRadius(16)
            }
        }
        .position(
            CGPoint(
                x: photoItem.position.x + photoItem.dragOffset.width,
                y: photoItem.position.y + photoItem.dragOffset.height
            )
        )
        .scaleEffect(photoItem.isDragging ? 1.05 : 1.0)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: photoItem.isDragging)
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    if let index = photoItems.firstIndex(where: { $0.id == photoItem.id }) {
                        photoItems[index].dragOffset = value.translation
                        if !photoItems[index].isDragging {
                            photoItems[index].isDragging = true
                            dragManager.isDraggingAny = true
                        }
                        
                        // Check if currently over trash bin, star button, or share button
                        let currentPosition = CGPoint(
                            x: photoItem.position.x + value.translation.width,
                            y: photoItem.position.y + value.translation.height
                        )
                        dragManager.isHoveringOverTrash = dragManager.isOverTrashBin?(currentPosition, photoItem, geometry) ?? false
                        dragManager.isHoveringOverShare = dragManager.isOverShareButton?(currentPosition, photoItem, geometry) ?? false
                        
                        // Only activate star if dragging a frameless photo
                        if photoItem.frameShape == nil {
                            dragManager.isHoveringOverStar = dragManager.isOverStarButton?(currentPosition, photoItem, geometry) ?? false
                        } else {
                            dragManager.isHoveringOverStar = false
                        }
                    }
                }
                .onEnded { value in
                    if let index = photoItems.firstIndex(where: { $0.id == photoItem.id }) {
                        let finalPosition = CGPoint(
                            x: photoItem.position.x + value.translation.width,
                            y: photoItem.position.y + value.translation.height
                        )
                        
                        // Check if dropped on trash bin, share button, or star button
                        if dragManager.isOverTrashBin?(finalPosition, photoItem, geometry) == true {
                            // Keep the item in its dragged position for deletion animation
                            photoItems[index].position.x += value.translation.width
                            photoItems[index].position.y += value.translation.height
                            photoItems[index].dragOffset = .zero
                            photoItems[index].isDragging = false
                            
                            // Animate deletion and hide trash bin
                            dragManager.deletePhotoItem?(index)
                            
                            // Reset drag states and animate trash bin out immediately
                            dragManager.resetDragStates()
                            
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragManager.trashBinOpacity = 0.0
                                dragManager.trashBinScale = 0.8
                            }
                        } else if dragManager.isOverShareButton?(finalPosition, photoItem, geometry) == true {
                            // Share photo functionality
                            photoItems[index].position.x += value.translation.width
                            photoItems[index].position.y += value.translation.height
                            photoItems[index].dragOffset = .zero
                            photoItems[index].isDragging = false
                            
                            // Export and share photo
                            dragManager.sharePhotoItem?(photoItem)
                            
                            // Reset drag states and animate share button out
                            dragManager.resetDragStates()
                            
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragManager.shareButtonOpacity = 0.0
                                dragManager.shareButtonScale = 0.8
                            }
                        } else if dragManager.isOverStarButton?(finalPosition, photoItem, geometry) == true && photoItem.frameShape == nil {
                            // Convert frameless photo to framed photo
                            photoItems[index].position.x += value.translation.width
                            photoItems[index].position.y += value.translation.height
                            photoItems[index].dragOffset = .zero
                            photoItems[index].isDragging = false
                            
                            // Convert to framed photo
                            dragManager.convertToFramedPhoto?(index)
                            
                            // Reset drag states and animate star button out
                            dragManager.resetDragStates()
                            
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragManager.starButtonOpacity = 0.0
                                dragManager.starButtonScale = 0.8
                            }
                        } else {
                            // Normal drop
                            photoItems[index].position.x += value.translation.width
                            photoItems[index].position.y += value.translation.height
                            photoItems[index].dragOffset = .zero
                            photoItems[index].isDragging = false
                            
                            // Reset drag states for normal drops
                            dragManager.resetDragStates()
                        }
                    }
                }
        )
    }
}
