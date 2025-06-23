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
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var dragViewModel = DragInteractionViewModel()
    @StateObject private var soundService = SoundService()
    @StateObject private var animationViewModel = AnimationViewModel()
    @StateObject private var photoItemsViewModel = PhotoItemsViewModel()
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var colorPhase: Double = 0
    @State private var isLoading = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
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
                
                ForEach(photoItemsViewModel.photoItems) { photoItem in
                    PhotoItemView(
                        photoItem: photoItem,
                        geometry: geometry,
                        photoItems: $photoItemsViewModel.photoItems,
                        dragViewModel: dragViewModel
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
                    .scaleEffect((authorizationStatus == .restricted ? 0.9 : 1.0) * animationViewModel.addButtonScale)
                    .opacity((authorizationStatus == .restricted ? 0.8 : 1.0) * animationViewModel.addButtonOpacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animationViewModel.addButtonScale)
                    .animation(.easeInOut(duration: 0.3), value: animationViewModel.addButtonOpacity)
                    .padding(.bottom, 120)
                    
                    // Button row with test button and envelope button
                    HStack(spacing: 20) {
                        // Test button
                        Button(action: {
                            if !testButtonLoading {
                            print("Test button tapped!")
                            testButtonLoading = true
                            photoItemsViewModel.addTestPhotoItem(backgroundRemover: photoViewModel.backgroundRemover) { success in
                                    self.testButtonLoading = false
                            }
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
                                    photoViewModel.currentMethod = method
                                }) {
                                    HStack {
                                        Image(systemName: method.iconName)
                                        Text(method.displayName)
                                        Spacer()
                                        if photoViewModel.currentMethod == method {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: photoViewModel.currentMethod.iconName)
                                    .foregroundColor(.white)
                                Text(photoViewModel.currentMethod.displayName)
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
                                .fill((dragViewModel.isHoveringOverTrash ? Color.red : Color.gray).gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            // Trash icon
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Poof effect
                            if animationViewModel.poofOpacity > 0 {
                                ZStack {
                                    // Multiple poof particles
                                    ForEach(0..<8, id: \.self) { index in
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(width: 6, height: 6)
                                            .offset(
                                                x: cos(Double(index) * .pi / 4) * 30 * animationViewModel.poofScale,
                                                y: sin(Double(index) * .pi / 4) * 30 * animationViewModel.poofScale
                                            )
                                    }
                                }
                                .scaleEffect(animationViewModel.poofScale)
                                .opacity(animationViewModel.poofOpacity)
                            }
                        }
                        .scaleEffect(dragViewModel.trashBinScale)
                        .opacity(dragViewModel.trashBinOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragViewModel.trashBinScale)
                        .animation(.easeInOut(duration: 0.3), value: dragViewModel.trashBinOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dragViewModel.isHoveringOverTrash)
                        .padding(.leading, 40)
                        .padding(.bottom, 20)
                        
                        Spacer()
                    }
                }
                .onChange(of: dragViewModel.isDraggingAny) { isDragging in
                    dragViewModel.updateDragStates(isDragging: isDragging)
                    animationViewModel.updateAddButtonVisibility(isDragging: isDragging)
                }
                
                // Star button in bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            // Star button background
                            Circle()
                                .fill((dragViewModel.isHoveringOverStar ? Color.yellow : Color.gray).gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            // Star icon
                            Image(systemName: "star.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Sparkle effect
                            if animationViewModel.sparkleOpacity > 0 {
                                ZStack {
                                    // Multiple sparkle particles
                                    ForEach(0..<12, id: \.self) { index in
                                        Image(systemName: "sparkle")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.yellow)
                                            .offset(
                                                x: cos(Double(index) * .pi / 6) * 40 * animationViewModel.sparkleScale,
                                                y: sin(Double(index) * .pi / 6) * 40 * animationViewModel.sparkleScale
                                            )
                                    }
                                }
                                .scaleEffect(animationViewModel.sparkleScale)
                                .opacity(animationViewModel.sparkleOpacity)
                            }
                        }
                        .scaleEffect(dragViewModel.starButtonScale)
                        .opacity(dragViewModel.starButtonOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragViewModel.starButtonScale)
                        .animation(.easeInOut(duration: 0.3), value: dragViewModel.starButtonOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dragViewModel.isHoveringOverStar)
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
                                .fill((dragViewModel.isHoveringOverShare ? Color.blue : Color.gray).gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            // Share icon
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Glow effect
                            if animationViewModel.shareGlowOpacity > 0 {
                                ZStack {
                                    // Multiple glow particles
                                    ForEach(0..<6, id: \.self) { index in
                                        Circle()
                                            .fill(Color.blue.opacity(0.6))
                                            .frame(width: 10, height: 10)
                                            .offset(
                                                x: cos(Double(index) * .pi / 3) * 35 * animationViewModel.shareGlowScale,
                                                y: sin(Double(index) * .pi / 3) * 35 * animationViewModel.shareGlowScale
                                            )
                                    }
                                }
                                .scaleEffect(animationViewModel.shareGlowScale)
                                .opacity(animationViewModel.shareGlowOpacity)
                            }
                        }
                        .scaleEffect(dragViewModel.shareButtonScale)
                        .opacity(dragViewModel.shareButtonOpacity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragViewModel.shareButtonScale)
                        .animation(.easeInOut(duration: 0.3), value: dragViewModel.shareButtonOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dragViewModel.isHoveringOverShare)
                        .padding(.bottom, 20)
                        Spacer()
                    }
                }
                
                // Image overlay for sound feedback
                SoundImageOverlay(
                    showOverlay: soundService.showImageOverlay,
                    imageName: soundService.currentImageName,
                    pulseScale: soundService.pulseScale
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
            dragViewModel.isOverTrashBin = HitTestingUtils.isOverTrashBin
            dragViewModel.isOverShareButton = HitTestingUtils.isOverShareButton
            dragViewModel.isOverStarButton = HitTestingUtils.isOverStarButton
            dragViewModel.deletePhotoItem = deletePhotoItem
            dragViewModel.sharePhotoItem = sharePhotoItem
            dragViewModel.convertToFramedPhoto = convertToFramedPhoto
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
    

    
    private func fetchRandomPhoto() {
        photoViewModel.fetchRandomPhoto { image, actualMethod in
            // Keep background removal and PhotoItem creation off main thread
            if let image = image {
                // Remove background from the image first
                self.photoViewModel.backgroundRemover.removeBackground(of: image) { processedImage in
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
                            shouldUseFrames = self.photoViewModel.currentMethod != .recentPhotos
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
                        self.photoItemsViewModel.photoItems.append(photoItem)
                        
                        // Loading complete - photo successfully added
                        self.isLoading = false
                        
                        // Play random Mario success sound
                        self.soundService.playMarioSuccessSound()
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
    

    
    private func sharePhotoItem(_ photoItem: PhotoItem) {
        // Trigger glow animation
        animationViewModel.triggerShareGlowAnimation()
        
        // Scale effect for share button
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dragViewModel.shareButtonScale = 1.1
        }
        
        // Generate image to share
        Task {
            await generateShareImage(from: photoItem)
        }
        
        // Reset share button scale after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                dragViewModel.shareButtonScale = 1.0
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
        // Trigger sparkle animation
        animationViewModel.triggerSparkleAnimation()
        
        // Scale effect for star button
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dragViewModel.starButtonScale = 1.2
        }
        
        // Convert using manager
        photoItemsViewModel.convertToFramedPhoto(at: index)
        
        // Reset star button scale after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.dragViewModel.starButtonScale = 1.0
            }
        }
    }
    
    private func deletePhotoItem(at index: Int) {
        // Trigger poof animation
        animationViewModel.triggerPoofAnimation()
        
        // Scale effect for trash bin
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dragViewModel.trashBinScale = 1.2
        }
        
        // Remove item using manager
        photoItemsViewModel.deletePhotoItem(at: index)
        
        // Reset trash bin scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.dragViewModel.trashBinScale = 1.0
            }
        }
    }
}





#Preview {
    RandomPhotoView()
}
