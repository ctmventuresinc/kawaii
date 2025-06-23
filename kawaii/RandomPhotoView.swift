//
//  RandomPhotoView.swift
//  daily-affirmations
//
//  Created by Los Mayers on 6/15/25.
//

import SwiftUI
import Photos
import AVFoundation
import Vision

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

@MainActor
class PhotoManager: ObservableObject {
    @Published var currentMethod: PhotoRetrievalMethod = .facePhotosLastMonth
    private var usedAssetIds: Set<String> = []
    private var usedFaceIds: Set<String> = []
    let backgroundRemover = BackgroundRemover()
    
    func fetchRandomPhoto(completion: @escaping (UIImage?, PhotoRetrievalMethod) -> Void) {
        print("🔍 DEBUG: fetchRandomPhoto() started")
        fetchRandomPhotoWithFallback(preferredMethod: currentMethod, completion: completion)
    }
    
    private func fetchRandomPhotoWithFallback(preferredMethod: PhotoRetrievalMethod, completion: @escaping (UIImage?, PhotoRetrievalMethod) -> Void) {
        switch preferredMethod {
        case .recentPhotos:
            fetchRandomRecentPhoto { image in
                completion(image, .recentPhotos)
            }
        case .recentPhotosWithSVG:
            fetchRandomRecentPhoto { image in
                completion(image, .recentPhotosWithSVG)
            }
        case .facePhotos:
            fetchRandomFaceCrop(timeframe: .recent) { [weak self] image in
                if image != nil {
                    completion(image, .facePhotos)
                } else {
                    print("Face Crops failed, falling back to Recent Photos")
                    self?.fetchRandomPhotoWithFallback(preferredMethod: .recentPhotos, completion: completion)
                }
            }
        case .facePhotos30Days:
            fetchRandomFaceCrop(timeframe: .thirtyDays) { [weak self] image in
                if image != nil {
                    completion(image, .facePhotos30Days)
                } else {
                    print("Face Crops (30 Days) failed, falling back to Recent Photos")
                    self?.fetchRandomPhotoWithFallback(preferredMethod: .recentPhotos, completion: completion)
                }
            }
        case .facePhotosLastMonth:
            fetchRandomFaceCrop(timeframe: .lastMonth) { [weak self] image in
                if image != nil {
                    completion(image, .facePhotosLastMonth)
                } else {
                    print("Face Crops (Last Month) failed, falling back to Recent Photos")
                    self?.fetchRandomPhotoWithFallback(preferredMethod: .recentPhotos, completion: completion)
                }
            }
        }
    }
    
    enum TimeFrame {
        case recent, thirtyDays, lastMonth
    }
    
    private func fetchRandomRecentPhoto(completion: @escaping (UIImage?) -> Void) {
        // Move ALL Photos framework operations to background queue
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 DEBUG: fetchRandomRecentPhoto() started on background queue")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 50
            
            print("🔍 DEBUG: About to call PHAsset.fetchAssets")
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("🔍 DEBUG: PHAsset.fetchAssets completed, found \(fetchResult.count) assets")
        
        guard fetchResult.count > 0 else {
            completion(nil)
            return
        }
        
        var attempts = 0
        let maxAttempts = 20
        
        print("🔍 DEBUG: Starting while loop to find unused asset")
        while attempts < maxAttempts {
            let randomIndex = Int.random(in: 0..<fetchResult.count)
            let randomAsset = fetchResult.object(at: randomIndex)
            
            if !randomAsset.mediaSubtypes.contains(.photoScreenshot) && 
               !self.usedAssetIds.contains(randomAsset.localIdentifier) {
                print("🔍 DEBUG: Found valid asset, calling loadPhoto")
                self.loadPhoto(asset: randomAsset, completion: completion)
                self.usedAssetIds.insert(randomAsset.localIdentifier)
                return
            }
            attempts += 1
        }
        print("🔍 DEBUG: No valid asset found after \(maxAttempts) attempts")
        completion(nil)
        }
    }
    
    private func fetchRandomFaceCrop(timeframe: TimeFrame, completion: @escaping (UIImage?) -> Void) {
        // Get photos from specified timeframe
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        switch timeframe {
        case .recent:
            fetchOptions.fetchLimit = 100
        case .thirtyDays:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", thirtyDaysAgo as NSDate)
            fetchOptions.fetchLimit = 200
        case .lastMonth:
            let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let lastMonthEnd = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", 
                                               lastMonthStart as NSDate, lastMonthEnd as NSDate)
            fetchOptions.fetchLimit = 300
        }
        
        let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard allAssets.count > 0 else {
            print("No photos found in specified timeframe")
            completion(nil) // Don't fallback - be strict about face crops
            return
        }
        
        // Try to find a photo with faces - be more persistent
        findPhotoWithFaces(from: allAssets, attempts: 0, maxAttempts: 50, completion: completion)
    }
    
    private func findPhotoWithFaces(from assets: PHFetchResult<PHAsset>, attempts: Int, maxAttempts: Int, completion: @escaping (UIImage?) -> Void) {
        guard attempts < maxAttempts, attempts < assets.count else {
            print("No faces found after \(attempts) attempts - STRICT MODE: No fallback")
            completion(nil) // Be strict - don't fallback to regular photos
            return
        }
        
        let randomIndex = Int.random(in: 0..<assets.count)
        let asset = assets.object(at: randomIndex)
        
        // Skip screenshots and already used assets
        if asset.mediaSubtypes.contains(.photoScreenshot) || usedAssetIds.contains(asset.localIdentifier) {
            findPhotoWithFaces(from: assets, attempts: attempts + 1, maxAttempts: maxAttempts, completion: completion)
            return
        }
        
        // Load the image and detect faces
        loadImageAndDetectFaces(asset: asset) { [weak self] faceImage in
            if let faceImage = faceImage {
                // Found a face! Mark asset as used and return the face crop
                self?.usedAssetIds.insert(asset.localIdentifier)
                completion(faceImage)
            } else {
                // No faces in this image, try next one
                self?.findPhotoWithFaces(from: assets, attempts: attempts + 1, maxAttempts: maxAttempts, completion: completion)
            }
        }
    }
    
    private func loadPhoto(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Load at display resolution (450px max) * 2 for retina * screen scale
        let maxDisplaySize: CGFloat = 450 // From your PhotoItem size range
        let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    private func loadImageAndDetectFaces(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Load at face crop display resolution (234px max) * 2 for retina * screen scale
        let maxFaceDisplaySize: CGFloat = 234 // From your face crop size range
        let targetPixelSize = maxFaceDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let fullImage = image else {
                completion(nil)
                return
            }
            
            // Detect faces using Vision framework
            self.detectAndCropFace(from: fullImage, completion: completion)
        }
    }
    
    private func detectAndCropFace(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation] else {
                // No faces detected
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Filter faces by minimum size (reject small background faces)
            let minFaceSize: CGFloat = 0.10 // Face must be at least 10% of image width/height
            let qualityFaces = observations.filter { face in
                return face.boundingBox.width > minFaceSize && face.boundingBox.height > minFaceSize
            }
            
            guard let firstQualityFace = qualityFaces.first else {
                // No quality faces found
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Crop the first quality face
            let croppedImage = self.cropFaceFromImage(image, faceObservation: firstQualityFace)
            DispatchQueue.main.async {
                completion(croppedImage)
            }
        }
        
        // Perform face detection on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func cropFaceFromImage(_ image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Convert Vision coordinates (bottom-left origin) to Core Graphics coordinates (top-left origin)
        let boundingBox = faceObservation.boundingBox
        let faceRect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        
        // Add padding around the face
        let padding: CGFloat = 0.4
        let paddedRect = CGRect(
            x: max(0, faceRect.origin.x - faceRect.width * padding),
            y: max(0, faceRect.origin.y - faceRect.height * padding),
            width: min(imageSize.width, faceRect.width * (1 + 2 * padding)),
            height: min(imageSize.height, faceRect.height * (1 + 2 * padding))
        )
        
        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: paddedRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

enum PhotoFilter: CaseIterable {
    case none, red, yellow, pink, orange, blackAndWhite
}

extension View {
    func applyPhotoFilter(_ filter: PhotoFilter) -> some View {
        switch filter {
        case .none:
            return AnyView(self)
        case .red:
            return AnyView(self.colorMultiply(.red))
        case .yellow:
            return AnyView(self.colorMultiply(.yellow))
        case .pink:
            return AnyView(self.colorMultiply(.pink))
        case .orange:
            return AnyView(self.colorMultiply(.orange))
        case .blackAndWhite:
            return AnyView(self.saturation(0))
        }
    }
}

struct PhotoItem: Identifiable {
    let id = UUID()
    let image: UIImage
    var position: CGPoint
    var dragOffset: CGSize = .zero
    var isDragging: Bool = false
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
        
        // Random photo filter from all available options
        self.photoFilter = PhotoFilter.allCases.randomElement() ?? .none
    }
}

struct SoundImagePair {
    let soundName: String
    let imageName: String
}



struct RandomPhotoView: View {
    @StateObject private var photoManager = PhotoManager()
    @State private var photoItems: [PhotoItem] = []
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var colorPhase: Double = 0
    @State private var isLoading = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var backgroundAudioPlayer: AVAudioPlayer?
    @State private var currentImageName: String = ""
    @State private var showImageOverlay = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var isDraggingAny = false
    @State private var trashBinScale: CGFloat = 1.0
    @State private var trashBinOpacity: Double = 0.0
    @State private var isHoveringOverTrash = false
    @State private var poofScale: CGFloat = 0.0
    @State private var poofOpacity: Double = 0.0
    @State private var starButtonScale: CGFloat = 1.0
    @State private var starButtonOpacity: Double = 0.0
    @State private var isHoveringOverStar = false
    @State private var sparkleScale: CGFloat = 0.0
    @State private var sparkleOpacity: Double = 0.0
    @State private var shareButtonScale: CGFloat = 1.0
    @State private var shareButtonOpacity: Double = 0.0
    @State private var isHoveringOverShare = false
    @State private var shareGlowScale: CGFloat = 0.0
    @State private var shareGlowOpacity: Double = 0.0
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var addButtonScale: CGFloat = 1.0
    @State private var addButtonOpacity: Double = 1.0
    @State private var testButtonLoading = false
    
    private let soundImagePairs: [SoundImagePair] = [
        SoundImagePair(soundName: "kawaii", imageName: "kawaii"),
        SoundImagePair(soundName: "saiyonara", imageName: "saiyonara"),
        SoundImagePair(soundName: "bombaclatt", imageName: "bombaclatt"),
        SoundImagePair(soundName: "nandeska", imageName: "nandeska")
    ]
    
    private let backgroundSounds = ["japan1", "japan2", "japan3", "boom"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Wallpaper background
                Image("wallpaper")
                    .resizable()
//                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                // Burst pattern background - commented out temporarily
                // BurstPatternBackground(rotationAngle: colorPhase * 360)
                //     .ignoresSafeArea()
                //     .onAppear {
                //         startBurstAnimation()
                //     }
                
                Color.clear
                    .contentShape(Rectangle())
                
                ForEach(photoItems) { photoItem in
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
                                        isDraggingAny = true
                                    }
                                    
                                    // Check if currently over trash bin, star button, or share button
                                    let currentPosition = CGPoint(
                                        x: photoItem.position.x + value.translation.width,
                                        y: photoItem.position.y + value.translation.height
                                    )
                                    isHoveringOverTrash = isOverTrashBin(position: currentPosition, photoItem: photoItem, geometry: geometry)
                                    isHoveringOverShare = isOverShareButton(position: currentPosition, photoItem: photoItem, geometry: geometry)
                                    
                                    // Only activate star if dragging a frameless photo
                                    if photoItem.frameShape == nil {
                                        isHoveringOverStar = isOverStarButton(position: currentPosition, photoItem: photoItem, geometry: geometry)
                                    } else {
                                        isHoveringOverStar = false
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
                                    if isOverTrashBin(position: finalPosition, photoItem: photoItem, geometry: geometry) {
                                        // Keep the item in its dragged position for deletion animation
                                        photoItems[index].position.x += value.translation.width
                                        photoItems[index].position.y += value.translation.height
                                        photoItems[index].dragOffset = .zero
                                        photoItems[index].isDragging = false
                                        
                                        // Animate deletion and hide trash bin
                                        deletePhotoItem(at: index)
                                        
                                        // Reset drag states and animate trash bin out immediately
                                        isDraggingAny = false
                                        isHoveringOverTrash = false
                                        
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            trashBinOpacity = 0.0
                                            trashBinScale = 0.8
                                        }
                                    } else if isOverShareButton(position: finalPosition, photoItem: photoItem, geometry: geometry) {
                                        // Share photo functionality
                                        photoItems[index].position.x += value.translation.width
                                        photoItems[index].position.y += value.translation.height
                                        photoItems[index].dragOffset = .zero
                                        photoItems[index].isDragging = false
                                        
                                        // Export and share photo
                                        sharePhotoItem(photoItem)
                                        
                                        // Reset drag states and animate share button out
                                        isDraggingAny = false
                                        isHoveringOverShare = false
                                        
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            shareButtonOpacity = 0.0
                                            shareButtonScale = 0.8
                                        }
                                    } else if isOverStarButton(position: finalPosition, photoItem: photoItem, geometry: geometry) && photoItem.frameShape == nil {
                                        // Convert frameless photo to framed photo
                                        photoItems[index].position.x += value.translation.width
                                        photoItems[index].position.y += value.translation.height
                                        photoItems[index].dragOffset = .zero
                                        photoItems[index].isDragging = false
                                        
                                        // Convert to framed photo
                                        convertToFramedPhoto(at: index)
                                        
                                        // Reset drag states and animate star button out
                                        isDraggingAny = false
                                        isHoveringOverStar = false
                                        
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            starButtonOpacity = 0.0
                                            starButtonScale = 0.8
                                        }
                                    } else {
                                        // Normal drop
                                        photoItems[index].position.x += value.translation.width
                                        photoItems[index].position.y += value.translation.height
                                        photoItems[index].dragOffset = .zero
                                        photoItems[index].isDragging = false
                                        
                                        // Reset drag states for normal drops
                                        isDraggingAny = false
                                        isHoveringOverTrash = false
                                        isHoveringOverStar = false
                                        isHoveringOverShare = false
                                    }
                                }
                            }
                    )
                }
                
                VStack {
                    Spacer()
                    Button(action: requestPhotoPermission) {
                        HStack(spacing: 8) {
                            Image(systemName: authorizationStatus == .denied ? "arrow.trianglehead.counterclockwise" : "photo.on.rectangle")
                            Text(buttonTitle)
                        }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.7, green: 0.85, blue: 1.0),
                                    Color(red: 0.5, green: 0.75, blue: 0.95)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.white.opacity(0.8), radius: 1, x: 0, y: 1)
                    }
                    .disabled(authorizationStatus == .restricted)
                    .scaleEffect((authorizationStatus == .restricted ? 0.9 : 1.0) * addButtonScale)
                    .opacity((authorizationStatus == .restricted ? 0.8 : 1.0) * addButtonOpacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: addButtonScale)
                    .animation(.easeInOut(duration: 0.3), value: addButtonOpacity)
                    .padding(.bottom, 120)
                    
                    // Button row with test button and envelope button
                    HStack(spacing: 20) {
                        // Test button
                        Button(action: {
                            if !testButtonLoading {
                                print("Test button tapped!")
                                testButtonLoading = true
                                addTestElement()
                            }
                        }) {
                            Text("Button")
                        }
                        .buttonStyle(LoadingGlossyButtonStyle(isLoading: testButtonLoading))
                        .disabled(testButtonLoading)
                        
                        // Envelope button
                        Button(action: {
                            print("Envelope button tapped!")
                        }) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 32, weight: .medium))
                        }
                        .buttonStyle(GlossyEnvelopeButtonStyle())
                    }
                    .padding(.bottom, 50)
                }
                
                // Photo method selector in top right
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            ForEach(PhotoRetrievalMethod.allCases, id: \.self) { method in
                                Button(action: {
                                    photoManager.currentMethod = method
                                }) {
                                    HStack {
                                        Image(systemName: method.iconName)
                                        Text(method.displayName)
                                        Spacer()
                                        if photoManager.currentMethod == method {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: photoManager.currentMethod.iconName)
                                    .foregroundColor(.white)
                                Text(photoManager.currentMethod.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
                
                // Trash bin in bottom left corner
                VStack {
                    Spacer()
                    HStack {
                        ZStack {
                            // Trash bin background
                            Circle()
                                .fill((isHoveringOverTrash ? Color.red : Color.gray).gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            // Trash icon
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Poof effect
                            if poofOpacity > 0 {
                                ZStack {
                                    // Multiple poof particles
                                    ForEach(0..<8, id: \.self) { index in
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(width: 6, height: 6)
                                            .offset(
                                                x: cos(Double(index) * .pi / 4) * 30 * poofScale,
                                                y: sin(Double(index) * .pi / 4) * 30 * poofScale
                                            )
                                    }
                                }
                                .scaleEffect(poofScale)
                                .opacity(poofOpacity)
                            }
                        }
                        .scaleEffect(trashBinScale)
                        .opacity(trashBinOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: trashBinScale)
                        .animation(.easeInOut(duration: 0.3), value: trashBinOpacity)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringOverTrash)
                        .padding(.leading, 40)
                        .padding(.bottom, 20)
                        
                        Spacer()
                    }
                }
                .onChange(of: isDraggingAny) { isDragging in
                    if isDragging {
                        trashBinOpacity = 1.0
                        trashBinScale = 1.0
                        starButtonOpacity = 1.0
                        starButtonScale = 1.0
                        shareButtonOpacity = 1.0
                        shareButtonScale = 1.0
                        addButtonOpacity = 0.0
                        addButtonScale = 0.8
                    } else {
                        trashBinOpacity = 0.0
                        trashBinScale = 0.8
                        starButtonOpacity = 0.0
                        starButtonScale = 0.8
                        shareButtonOpacity = 0.0
                        shareButtonScale = 0.8
                        addButtonOpacity = 1.0
                        addButtonScale = 1.0
                    }
                }
                
                // Star button in bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            // Star button background
                            Circle()
                                .fill((isHoveringOverStar ? Color.yellow : Color.gray).gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            // Star icon
                            Image(systemName: "star.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Sparkle effect
                            if sparkleOpacity > 0 {
                                ZStack {
                                    // Multiple sparkle particles
                                    ForEach(0..<12, id: \.self) { index in
                                        Image(systemName: "sparkle")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.yellow)
                                            .offset(
                                                x: cos(Double(index) * .pi / 6) * 40 * sparkleScale,
                                                y: sin(Double(index) * .pi / 6) * 40 * sparkleScale
                                            )
                                    }
                                }
                                .scaleEffect(sparkleScale)
                                .opacity(sparkleOpacity)
                            }
                        }
                        .scaleEffect(starButtonScale)
                        .opacity(starButtonOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: starButtonScale)
                        .animation(.easeInOut(duration: 0.3), value: starButtonOpacity)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringOverStar)
                        .padding(.trailing, 40)
                        .padding(.bottom, 20)
                    }
                }
                
                // Share button in bottom center
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            // Share button background
                            Circle()
                                .fill((isHoveringOverShare ? Color.blue : Color.gray).gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            // Share icon
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Glow effect
                            if shareGlowOpacity > 0 {
                                ZStack {
                                    // Multiple glow particles
                                    ForEach(0..<6, id: \.self) { index in
                                        Circle()
                                            .fill(Color.blue.opacity(0.6))
                                            .frame(width: 10, height: 10)
                                            .offset(
                                                x: cos(Double(index) * .pi / 3) * 35 * shareGlowScale,
                                                y: sin(Double(index) * .pi / 3) * 35 * shareGlowScale
                                            )
                                    }
                                }
                                .scaleEffect(shareGlowScale)
                                .opacity(shareGlowOpacity)
                            }
                        }
                        .scaleEffect(shareButtonScale)
                        .opacity(shareButtonOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: shareButtonScale)
                        .animation(.easeInOut(duration: 0.3), value: shareButtonOpacity)
                        .animation(.easeInOut(duration: 0.2), value: isHoveringOverShare)
                        .padding(.bottom, 20)
                        Spacer()
                    }
                }
                
                // Image overlay for sound feedback
                SoundImageOverlay(
                    showOverlay: showImageOverlay,
                    imageName: currentImageName,
                    pulseScale: pulseScale
                )
                .onAppear {
                    if showImageOverlay {
                        startPulsing()
                    }
                }
                
                // Screen center loading indicator
                LoadingOverlay(isLoading: isLoading)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage = shareImage {
                ActivityView(activityItems: [shareImage])
                    .presentationDetents([.fraction(0.5), .large])
            }
        }
        .onAppear {
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
    }
    
    private var buttonTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Allow Full Access"
        case .restricted, .denied:
            return "Photo Access Denied"
        case .authorized, .limited:
            return "Add"
        @unknown default:
            return "Allow Full Access"
        }
    }
    
    private func requestPhotoPermission() {
        switch authorizationStatus {
        case .notDetermined:
            isLoading = true
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    if status == .authorized || status == .limited {
                        self.fetchRandomPhoto()
                    } else {
                        self.isLoading = false
                    }
                }
            }
        case .authorized, .limited:
            isLoading = true
            fetchRandomPhoto()
        case .denied, .restricted:
            openAppSettings()
        @unknown default:
            break
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    private func addTestElement() {
        print("🔍 DEBUG: addTestElement() called - START")
        
        // Move ALL Photos framework operations to background queue
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 DEBUG: Now on background queue")
            
            // Get the most recent photo in the simplest way possible
            print("🔍 DEBUG: About to create fetch options")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1 // Just get the most recent
            
            print("🔍 DEBUG: About to call PHAsset.fetchAssets")
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("🔍 DEBUG: PHAsset.fetchAssets completed, found \(fetchResult.count) assets")
        
        guard fetchResult.count > 0 else {
            print("🔍 DEBUG: No photos found")
            DispatchQueue.main.async {
                self.testButtonLoading = false
            }
            return
        }
        
        let mostRecentAsset = fetchResult.object(at: 0)
        print("🔍 DEBUG: Got most recent asset, about to request image")
        
        // Request the image at high quality (matching regular Add button)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Load at display resolution (450px max) * 2 for retina * screen scale
        let maxDisplaySize: CGFloat = 450 // Same as regular Add button
        let targetPixelSize = maxDisplaySize * 2.0 * UIScreen.main.scale
        
        PHImageManager.default().requestImage(
            for: mostRecentAsset,
            targetSize: CGSize(width: targetPixelSize, height: targetPixelSize),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            print("🔍 DEBUG: Image request completed")
            guard let image = image else {
                print("🔍 DEBUG: No image returned")
                DispatchQueue.main.async {
                    self.testButtonLoading = false
                }
                return
            }
            
            print("🔍 DEBUG: Got image, applying background removal")
            // Apply background removal to make it transparent/cut out
            self.photoManager.backgroundRemover.removeBackground(of: image) { processedImage in
                print("🔍 DEBUG: Background removal completed")
                let finalImage = processedImage ?? image // Use original if background removal fails
                
                DispatchQueue.main.async {
                    print("🔍 DEBUG: Back on main queue with processed image")
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    let randomX = CGFloat.random(in: 100...(screenWidth - 100))
                    let randomY = CGFloat.random(in: 100...(screenHeight - 200))
                    
                    // Add SVG frames like regular Add button
                    let frameShape = FaceFrameShape.allCases.randomElement()
                    print("🔍 DEBUG: Added SVG frame: \(frameShape != nil ? "irregularBurst" : "none")")
                    
                    // Use same size range as regular Add button
                    let size: CGFloat = CGFloat.random(in: 153...234)
                    
                    let testPhotoItem = PhotoItem(
                        image: finalImage,
                        position: CGPoint(x: randomX, y: randomY),
                        frameShape: frameShape,
                        size: size
                    )
                    
                    print("🔍 DEBUG: About to append PhotoItem with cut-out background")
                    self.photoItems.append(testPhotoItem)
                    
                    // Reset loading state
                    self.testButtonLoading = false
                    print("🔍 DEBUG: PhotoItem appended - END")
                }
            }
        }
        }
    }
    
    private func fetchRandomPhoto() {
        photoManager.fetchRandomPhoto { image, actualMethod in
            // Keep background removal and PhotoItem creation off main thread
            if let image = image {
                // Remove background from the image first
                self.photoManager.backgroundRemover.removeBackground(of: image) { processedImage in
                        let finalImage = processedImage ?? image // Use original if background removal fails
                        
                        let screenWidth = UIScreen.main.bounds.width
                        let screenHeight = UIScreen.main.bounds.height
                        let randomX = CGFloat.random(in: 100...(screenWidth - 100))
                        let randomY = CGFloat.random(in: 100...(screenHeight - 200))
                        
                        // Determine frame usage
                        let shouldUseFrames: Bool
                        switch actualMethod {
                        case .recentPhotos:
                            // Regular recent photos - no frames unless fallback from face crop mode
                            shouldUseFrames = self.photoManager.currentMethod != .recentPhotos
                        case .recentPhotosWithSVG:
                            // Intentional SVG recent photos - always use frames
                            shouldUseFrames = true
                        default:
                            // Face crop modes - always use frames
                            shouldUseFrames = true
                        }
                        
                        let frameShape = shouldUseFrames ? FaceFrameShape.allCases.randomElement() : nil
                        
                        // Standardized size for all photo types - creates cohesive collaging experience
                        let size: CGFloat = CGFloat.random(in: 153...234)
                        
                        let photoItem = PhotoItem(
                            image: finalImage,
                            position: CGPoint(x: randomX, y: randomY),
                            frameShape: frameShape,
                            size: size
                        )
                        
                        // Only UI updates on main thread
                        DispatchQueue.main.async {
                            self.photoItems.append(photoItem)
                            
                            // Loading complete - photo successfully added
                            self.isLoading = false
                            
                            // Play random Mario success sound
                            self.playMarioSuccessSound()
                        }
                    }
            } else {
                // This should never happen now due to fallback system
                print("No photos found even after fallback - check photo library permissions")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    

    
    private func playMarioSuccessSound() {
        let randomPair = soundImagePairs.randomElement() ?? soundImagePairs[0]
        
        guard let path = Bundle.main.path(forResource: randomPair.soundName, ofType: "mp3") else {
            print("Could not find sound file: \(randomPair.soundName).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Configure audio session for mixing multiple sounds
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and store the main audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Play random background sound simultaneously
            playRandomBackgroundSound()
            
            // Show image overlay
            showImageOverlay(for: randomPair.imageName)
        } catch {
            print("Could not play sound: \(error)")
        }
    }
    
    private func playRandomBackgroundSound() {
        let randomBackgroundSound = backgroundSounds.randomElement() ?? backgroundSounds[0]
        
        guard let path = Bundle.main.path(forResource: randomBackgroundSound, ofType: "mp3") else {
            print("Could not find background sound file: \(randomBackgroundSound).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Create and store the background audio player
            backgroundAudioPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundAudioPlayer?.volume = 0.7 // Slightly lower volume for background
            backgroundAudioPlayer?.prepareToPlay()
            backgroundAudioPlayer?.play()
        } catch {
            print("Could not play background sound: \(error)")
        }
    }
    
    private func showImageOverlay(for imageName: String) {
        currentImageName = imageName
        showImageOverlay = true
        startPulsing()
        
        // Hide the image after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showImageOverlay = false
            self.pulseScale = 1.0 // Stop pulsing
            
            // Clear the image name after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentImageName = ""
            }
        }
    }
    
    private func startPulsing() {
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
    
    private func startBurstAnimation() {
        // Slow rotation animation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            colorPhase = 1.0
        }
    }
    
    private func isOverTrashBin(position: CGPoint, photoItem: PhotoItem, geometry: GeometryProxy) -> Bool {
        let trashBinCenter = CGPoint(x: 70, y: geometry.size.height - 50) // 40 padding + 30 radius
        let trashBinRadius: CGFloat = 30 // Half of trash bin size (60/2)
        
        // Calculate PhotoItem's effective radius - more conservative approach
        let photoItemRadius: CGFloat
        if photoItem.frameShape != nil {
            // Face crops with frames - use background shape size instead of outer stroke for less sensitivity
            photoItemRadius = (photoItem.size + 60) / 2 // Much smaller buffer
        } else {
            // Regular photos
            photoItemRadius = photoItem.size / 2
        }
        
        let distance = sqrt(pow(position.x - trashBinCenter.x, 2) + pow(position.y - trashBinCenter.y, 2))
        let totalRadius = trashBinRadius + photoItemRadius - 5 // Reduce tolerance to make it less sensitive
        
        return distance <= totalRadius
    }
    
    private func isOverStarButton(position: CGPoint, photoItem: PhotoItem, geometry: GeometryProxy) -> Bool {
        let starButtonCenter = CGPoint(x: geometry.size.width - 70, y: geometry.size.height - 50) // 40 padding + 30 radius from right
        let starButtonRadius: CGFloat = 30 // Half of star button size (60/2)
        
        // Calculate PhotoItem's effective radius 
        let photoItemRadius = photoItem.size / 2 // Only for regular photos without frames
        
        let distance = sqrt(pow(position.x - starButtonCenter.x, 2) + pow(position.y - starButtonCenter.y, 2))
        let totalRadius = starButtonRadius + photoItemRadius - 5 // Same tolerance as trash bin
        
        return distance <= totalRadius
    }
    
    private func isOverShareButton(position: CGPoint, photoItem: PhotoItem, geometry: GeometryProxy) -> Bool {
        let shareButtonCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 50) // Center horizontally, same vertical position
        let shareButtonRadius: CGFloat = 30 // Half of share button size (60/2)
        
        // Calculate PhotoItem's effective radius
        let photoItemRadius: CGFloat
        if photoItem.frameShape != nil {
            // Face crops with frames
            photoItemRadius = (photoItem.size + 60) / 2
        } else {
            // Regular photos
            photoItemRadius = photoItem.size / 2
        }
        
        let distance = sqrt(pow(position.x - shareButtonCenter.x, 2) + pow(position.y - shareButtonCenter.y, 2))
        let totalRadius = shareButtonRadius + photoItemRadius - 5 // Same tolerance as other buttons
        
        return distance <= totalRadius
    }
    
    private func sharePhotoItem(_ photoItem: PhotoItem) {
        // Trigger glow animation
        withAnimation(.easeOut(duration: 0.4)) {
            shareGlowScale = 1.0
            shareGlowOpacity = 1.0
        }
        
        // Scale effect for share button
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            shareButtonScale = 1.1
        }
        
        // Generate image to share
        Task {
            await generateShareImage(from: photoItem)
        }
        
        // Hide glow effect after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                shareGlowScale = 0.0
                shareGlowOpacity = 0.0
                shareButtonScale = 1.0
            }
        }
    }
    
    @MainActor
    private func generateShareImage(from photoItem: PhotoItem) async {
        // Create a renderer to generate the image
        let renderer = ImageRenderer(content: 
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
        )
        
        renderer.scale = 3.0 // High resolution for sharing
        
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
    }
    
    private func convertToFramedPhoto(at index: Int) {
        guard index < photoItems.count else { return }
        
        // Trigger sparkle animation
        withAnimation(.easeOut(duration: 0.4)) {
            sparkleScale = 1.0
            sparkleOpacity = 1.0
        }
        
        // Scale effect for star button
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            starButtonScale = 1.2
        }
        
        // Create new PhotoItem with frame
        let currentItem = photoItems[index]
        let frameShape = FaceFrameShape.allCases.randomElement()
        let newSize = CGFloat.random(in: 153...234) // Face crop size range
        
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
        let backgroundColor = Color(hex: selectedCombo.background)
        let strokeColor = Color(hex: selectedCombo.button)
        
        let shapeNames = ["harmonyshape", "shape2", "shape3", "shape4"]
        let shapeName = shapeNames.randomElement() ?? "harmonyshape"
        
        let photoFilter = PhotoFilter.allCases.randomElement() ?? .none
        
        // Update the existing PhotoItem
        photoItems[index] = PhotoItem(
            image: currentItem.image,
            position: currentItem.position,
            frameShape: frameShape,
            size: newSize
        )
        
        // Reset animations after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.sparkleOpacity = 0.0
                self.starButtonScale = 1.0
            }
            
            // Reset sparkle scale for next use
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sparkleScale = 0.0
            }
        }
    }
    
    private func deletePhotoItem(at index: Int) {
        // Trigger poof animation
        withAnimation(.easeOut(duration: 0.3)) {
            poofScale = 1.0
            poofOpacity = 1.0
        }
        
        // Scale effect for trash bin
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            trashBinScale = 1.2
        }
        
        // Remove item after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if index < self.photoItems.count {
                self.photoItems.remove(at: index)
            }
        }
        
        // Reset animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.poofOpacity = 0.0
                self.trashBinScale = 1.0
            }
            
            // Reset poof scale for next use
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.poofScale = 0.0
            }
        }
    }
}





#Preview {
    RandomPhotoView()
}
