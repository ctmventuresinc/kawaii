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











struct RandomPhotoView: View {
    @StateObject private var photoManager = PhotoManager()
    @StateObject private var dragManager = DragInteractionManager()
    @StateObject private var soundManager = SoundManager()
    @State private var photoItems: [PhotoItem] = []
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var colorPhase: Double = 0
    @State private var isLoading = false
    @State private var poofScale: CGFloat = 0.0
    @State private var poofOpacity: Double = 0.0
    @State private var sparkleScale: CGFloat = 0.0
    @State private var sparkleOpacity: Double = 0.0
    @State private var shareGlowScale: CGFloat = 0.0
    @State private var shareGlowOpacity: Double = 0.0
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var addButtonScale: CGFloat = 1.0
    @State private var addButtonOpacity: Double = 1.0
    @State private var testButtonLoading = false
    
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
                    PhotoItemView(
                        photoItem: photoItem,
                        geometry: geometry,
                        photoItems: $photoItems,
                        dragManager: dragManager
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
                                .fill((dragManager.isHoveringOverTrash ? Color.red : Color.gray).gradient)
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
                        .scaleEffect(dragManager.trashBinScale)
                        .opacity(dragManager.trashBinOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragManager.trashBinScale)
                        .animation(.easeInOut(duration: 0.3), value: dragManager.trashBinOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dragManager.isHoveringOverTrash)
                        .padding(.leading, 40)
                        .padding(.bottom, 20)
                        
                        Spacer()
                    }
                }
                .onChange(of: dragManager.isDraggingAny) { isDragging in
                    dragManager.updateDragStates(isDragging: isDragging)
                    if isDragging {
                        addButtonOpacity = 0.0
                        addButtonScale = 0.8
                    } else {
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
                                .fill((dragManager.isHoveringOverStar ? Color.yellow : Color.gray).gradient)
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
                        .scaleEffect(dragManager.starButtonScale)
                        .opacity(dragManager.starButtonOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragManager.starButtonScale)
                        .animation(.easeInOut(duration: 0.3), value: dragManager.starButtonOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dragManager.isHoveringOverStar)
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
                                .fill((dragManager.isHoveringOverShare ? Color.blue : Color.gray).gradient)
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
                        .scaleEffect(dragManager.shareButtonScale)
                        .opacity(dragManager.shareButtonOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragManager.shareButtonScale)
                        .animation(.easeInOut(duration: 0.3), value: dragManager.shareButtonOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dragManager.isHoveringOverShare)
                        .padding(.bottom, 20)
                        Spacer()
                    }
                }
                
                // Image overlay for sound feedback
                SoundImageOverlay(
                    showOverlay: soundManager.showImageOverlay,
                    imageName: soundManager.currentImageName,
                    pulseScale: soundManager.pulseScale
                )
                
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
            
            // Setup drag manager actions
            dragManager.isOverTrashBin = isOverTrashBin
            dragManager.isOverShareButton = isOverShareButton
            dragManager.isOverStarButton = isOverStarButton
            dragManager.deletePhotoItem = deletePhotoItem
            dragManager.sharePhotoItem = sharePhotoItem
            dragManager.convertToFramedPhoto = convertToFramedPhoto
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
                            self.soundManager.playMarioSuccessSound()
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
            dragManager.shareButtonScale = 1.1
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
                dragManager.shareButtonScale = 1.0
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
            dragManager.starButtonScale = 1.2
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
                self.dragManager.starButtonScale = 1.0
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
            dragManager.trashBinScale = 1.2
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
                self.dragManager.trashBinScale = 1.0
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
