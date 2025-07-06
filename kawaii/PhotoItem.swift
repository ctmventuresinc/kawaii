//
//  PhotoItem.swift
//  kawaii
//
//  Created by AI Assistant on 6/22/25.
//

import SwiftUI
import UIKit

// Color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Photo retrieval methods
enum PhotoRetrievalMethod: String, CaseIterable {
    case recentPhotos = "Recent Photos"
    case recentPhotosWithSVG = "Recent Photos with SVG"
    case facePhotos = "Face Crops"
    case facePhotos30Days = "Face Crops (30 Days)" 
    case facePhotosLastMonth = "Face Crops (Last Month)"
    
    var displayName: String { self.rawValue }
    var iconName: String {
        switch self {
        case .recentPhotos: return "photo.on.rectangle"
        case .recentPhotosWithSVG: return "photo.on.rectangle.angled"
        case .facePhotos: return "person.crop.circle"
        case .facePhotos30Days: return "person.crop.circle.badge.clock"
        case .facePhotosLastMonth: return "person.crop.circle.badge.calendar"
        }
    }
}

// Frame shapes for face crops
enum FaceFrameShape: CaseIterable {
    case irregularBurst
}

// Photo filters
enum PhotoFilter: CaseIterable {
    case none, red, pink, orange, blackAndWhite, customColor(String)
    
    static var allCases: [PhotoFilter] {
        return [.none, .red, .pink, .orange, .blackAndWhite]
    }
}

// Photo filter extension
extension View {
    func applyPhotoFilter(_ filter: PhotoFilter) -> some View {
        switch filter {
        case .none:
            return AnyView(self)
        case .red:
            return AnyView(self.colorMultiply(Color(hex: "#FF4757") ?? .red)) // Bright coral-red
        case .pink:
            return AnyView(self.colorMultiply(Color(hex: "#FF6B9D") ?? .pink)) // Bright bubblegum pink
        case .orange:
            return AnyView(self.colorMultiply(Color(hex: "#FF8C42") ?? .orange)) // Bright tangerine
        case .blackAndWhite:
            return AnyView(self.saturation(0))
        case .customColor(let hexColor):
            return AnyView(self.colorMultiply(Color(hex: hexColor) ?? .clear))
        }
    }
}

// Custom shapes
struct IrregularBurstShape: Shape {
    /// Randomized radii for each instance - 24 points for variety
    private let radii: [CGFloat]
    
    init() {
        // Generate random radii with spikes and valleys
        var randomRadii: [CGFloat] = []
        for i in 0..<24 {
            if i % 2 == 0 {
                // Spikes: vary between 0.85-1.0
                randomRadii.append(CGFloat.random(in: 0.85...1.0))
            } else {
                // Valleys: vary between 0.45-0.65
                randomRadii.append(CGFloat.random(in: 0.45...0.65))
            }
        }
        self.radii = randomRadii
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let base = min(rect.width, rect.height) / 2
        let step = 2 * .pi / CGFloat(radii.count)
        
        for (i, r) in radii.enumerated() {
            let θ = CGFloat(i) * step - .pi / 2
            let p = CGPoint(x: c.x + cos(θ) * base * r,
                            y: c.y + sin(θ) * base * r)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }
}

// Photo item model
struct PhotoItem: Identifiable {
    let id = UUID()
    let image: UIImage
    var position: CGPoint
    var dragOffset: CGSize = .zero
    var isDragging: Bool = false
    var scale: CGFloat = 1.0
    let frameShape: FaceFrameShape?
    let size: CGFloat
    let strokeColor: Color
    let backgroundColor: Color
    let burstShape: IrregularBurstShape? // Keep for later use
    let shapeName: String // Store the selected shape name
    let photoFilter: PhotoFilter
    
    init(image: UIImage, position: CGPoint, frameShape: FaceFrameShape? = nil, size: CGFloat = 300) {
        self.image = image
        self.position = position
        self.frameShape = frameShape
        self.size = size
        
        // Color combinations for stroke and background
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
        
        let selectedCombo = colorCombinations.randomElement() ?? colorCombinations[0]
        self.backgroundColor = Color(hex: selectedCombo.background)
        self.strokeColor = Color(hex: selectedCombo.button)
        
        // Pick a random shape once and store it
        let shapeNames = ["harmonyshape", "shape2", "shape3", "shape4"]
        self.shapeName = shapeNames.randomElement() ?? "harmonyshape"
        
        // Keep burst shape creation for later use
        self.burstShape = frameShape != nil ? IrregularBurstShape() : nil
        
        // Assign filter based on frame type
        if frameShape != nil {
            // Framed photos - use the third color from the combination as filter
            self.photoFilter = .customColor(selectedCombo.inviteButtonColor)
        } else {
            // Regular photos without frames - 50% none, 50% split between 4 filter options
            let shouldApplyFilter = Bool.random()
            if shouldApplyFilter {
                let filterOptions: [PhotoFilter] = [
                    .blackAndWhite,
                    .customColor("#FFEA00"),  // Yellow
                    .customColor("#FBECCF"),  // Cream  
                    .customColor("#FA7921")   // Orange
                ]
                self.photoFilter = filterOptions.randomElement() ?? .blackAndWhite
            } else {
                self.photoFilter = .none
            }
        }
    }
}

// Sound image pair
struct SoundImagePair {
    let soundName: String
    let imageName: String
}
