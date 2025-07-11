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
import OneSignalFramework



struct RandomPhotoView: View {
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var dragViewModel = DragInteractionViewModel()
    @StateObject private var soundService = SoundService()
    @StateObject private var photoModeManager = PhotoModeManager()
    @StateObject private var animationViewModel = AnimationViewModel()
    @StateObject private var photoItemsViewModel = PhotoItemsViewModel()
    @StateObject private var shareService = ShareService()
    @StateObject private var dateSelectionViewModel = DateSelectionViewModel()
    @StateObject private var shareManager: ShareManager
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var colorPhase: Double = 0
    @State private var testButtonLoading = false
    @State private var blinkingOpacity: Double = 0.0
    @State private var hasBeenTapped = false

    @State private var topText = "this is not an app"
    @State private var topTextOpacity: Double = 1.0
    @State private var showTravelOverlay = false

    @State private var showEnjoymentAlert = false
    @State private var hasPendingTimeTravel = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var hasShownAppLaunchNotificationPrompt = false
    
    // State to control splash screen visibility
    @State private var showingSplash = true
    
    // State to control turtle mode
    @State private var isTurtleMode = false
    
    init() {
        let shareService = ShareService()
        let soundService = SoundService()
        _shareService = StateObject(wrappedValue: shareService)
        _soundService = StateObject(wrappedValue: soundService)
        _shareManager = StateObject(wrappedValue: ShareManager(shareService: shareService, soundService: soundService))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - switches based on app store review mode
                if FeatureFlags.shared.appStoreReviewMode {
                    Color.blue
                        .ignoresSafeArea()
                } else {
					Image(.blankwallpaper)
                        .resizable()
                        .ignoresSafeArea()
                }
                
                // Show splash screen or main content
                if showingSplash {
                    SplashScreen()
                } else {
                    // Main app content
                
                // Burst pattern background - commented out temporarily
                // BurstPatternBackground(rotationAngle: colorPhase * 360)
                //     .ignoresSafeArea()
                //     .onAppear {
                //         animationViewModel.startBurstAnimation(colorPhase: $colorPhase)
                //     }
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleScreenTap()
                    }
                
                // Blue background overlay (above current background, below dock)
                if isTurtleMode {
                    TurtleModeBackgroundView()
                        .animation(.easeInOut(duration: 0.3), value: isTurtleMode)
                }
                
                // Dock image at bottom of screen - behind ALL buttons
                VStack {
                    Spacer()
                    Image("dock")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 1.0, y: 1.35, anchor: .bottom)
                }
                .ignoresSafeArea(.all, edges: .bottom)
                
                // Independent top text that cycles through phrases
                VStack {
                    Text(topText)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .opacity(hasBeenTapped ? topTextOpacity : 0.0)
                        .animation(.easeInOut(duration: 0.65), value: topTextOpacity)
                        .animation(.easeInOut(duration: 0.65), value: hasBeenTapped)
                        .padding(.top, 50)
                        .onAppear {
                            startTopTextCycle()
                            soundService.playSound(.intro)
                        }
                    Spacer()
                }
                .opacity(isTurtleMode ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isTurtleMode)
                
                ForEach(photoItemsViewModel.photoItems) { photoItem in
                    PhotoItemView(
                        photoItem: photoItem,
                        geometry: geometry,
                        photoItems: $photoItemsViewModel.photoItems,
                        dragViewModel: dragViewModel
                    )
                }
                .opacity(isTurtleMode ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isTurtleMode)
                
                // Add button - TEMPORARILY HIDDEN
                /*
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
                */
                
                // Blinking instruction text in center of screen and buttons
                VStack {
                    Spacer()
                    
                    // Conditional instruction text
                    if !hasBeenTapped {
                        Text("Touch the Touch Screen to continue.")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(.black)
                            .opacity(isTurtleMode ? 0 : blinkingOpacity)
                            .animation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true), value: blinkingOpacity)
                            .animation(.easeInOut(duration: 0.3), value: isTurtleMode)
                            .onAppear {
                                blinkingOpacity = 1.0
                            }
                    }
                    
                    Spacer()
                    
                    // Button layout with centered main button and right-aligned envelope
                    ZStack {
                    // Centered rewind button
                    ZStack {
                        // Lock icon behind the button - offset to be visible
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.gray)
                            .offset(x: -60, y: 0)
                        
                        // Rewind button on top
                        Button(action: {
                        soundService.playSound(.click)
                        if isTurtleMode {
                                photoItemsViewModel.addTestPhotoItem(backgroundRemover: photoViewModel.backgroundRemover, soundService: soundService, dateSelection: dateSelectionViewModel, photoMode: photoModeManager.currentMode) { success in
                                print("Photo added via try now: \(success)")
                                }
                             } else {
                                 handleRewindAction()
                             }
                         }) {
                             Text(isTurtleMode ? "Try Now" : "Rewind")
                         }
                    }
                    .buttonStyle(LoadingGlossyButtonStyle(isLoading: false))
                    .disabled(false)
                    .scaleEffect(animationViewModel.addButtonScale)
                    .opacity(shareManager.areButtonsHidden ? 0 : animationViewModel.addButtonOpacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animationViewModel.addButtonScale)
                    .animation(.easeInOut(duration: 0.3), value: animationViewModel.addButtonOpacity)
                    .animation(.easeInOut(duration: 0.3), value: shareManager.areButtonsHidden)
                    
                    // Face button aligned to far left and Share button aligned to far right
                    HStack {
                    Button(action: {
                    toggleTurtleMode()
                    }) {
                    Image(systemName: isTurtleMode ? "xmark.circle.fill" : "tortoise.fill")
                    .font(.system(size: 32, weight: .medium))
                    }
                    .buttonStyle(GlossyEnvelopeButtonStyle())
                    .scaleEffect(0.6 * dragViewModel.faceButtonScale)
                    .opacity(shareManager.areButtonsHidden ? 0 : dragViewModel.faceButtonOpacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragViewModel.faceButtonScale)
                    .animation(.easeInOut(duration: 0.3), value: dragViewModel.faceButtonOpacity)
                    .animation(.easeInOut(duration: 0.3), value: shareManager.areButtonsHidden)
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                    shareManager.shareScreenshot()
                    }) {
                    Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 32, weight: .medium))
                    }
                    .buttonStyle(GlossyEnvelopeButtonStyle())
                    .scaleEffect(0.6 * dragViewModel.rewindButtonScale)
                    .opacity(shareManager.areButtonsHidden ? 0 : dragViewModel.rewindButtonOpacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragViewModel.rewindButtonScale)
                    .animation(.easeInOut(duration: 0.3), value: dragViewModel.rewindButtonOpacity)
                    .animation(.easeInOut(duration: 0.3), value: shareManager.areButtonsHidden)
                    .padding(.trailing, 20)
                    }
                    }
                    .padding(.bottom, 50)
                    }
                
                // Photo method selector in top right - TEMPORARILY COMMENTED OUT
                /*
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
                */
                
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
                .opacity(isTurtleMode ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isTurtleMode)
                .onChange(of: dragViewModel.isDraggingAny) { _, isDragging in
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
                .opacity(isTurtleMode ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isTurtleMode)
                
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
                LoadingOverlay(isLoading: photoItemsViewModel.isLoading)
                
                // Travel overlay
                if showTravelOverlay {
                    Rectangle()
                        .fill(Color.black.opacity(0.9))
                        .ignoresSafeArea()
                        .overlay(
                            VStack {
                                Text("traveling to")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(.white)
                                Text(dateSelectionViewModel.formattedTravelDate)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        )
                        .opacity(showTravelOverlay ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: showTravelOverlay)
                }
                } // End of main app content conditional
            }
        }
        .task {
            // Show splash screen for exactly 2 seconds
			try? await Task.sleep(for: .seconds(2.5))
            showingSplash = false
            
            // Start animations and sounds after splash screen disappears
            startTopTextCycle()
            soundService.playSound(.intro)
        }
        .sheet(isPresented: $shareService.showShareSheet) {
            let activityItems: [Any] = {
                var items: [Any] = []
                if let shareText = shareService.shareText {
                    items.append(shareText)
                }
                if let shareImage = shareService.shareImage {
                    items.append(shareImage)
                }
                return items
            }()
            
            ActivityView(activityItems: activityItems)
                .presentationDetents([.fraction(0.5), .large])
        }
        .onAppear {
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            // Setup ShareService dependencies
            shareService.animationViewModel = animationViewModel
            shareService.dragViewModel = dragViewModel
            
            // Setup drag manager actions
            dragViewModel.isOverTrashBin = HitTestingUtils.isOverTrashBin
            dragViewModel.isOverShareButton = HitTestingUtils.isOverShareButton
            dragViewModel.isOverStarButton = HitTestingUtils.isOverStarButton
            dragViewModel.deletePhotoItem = deletePhotoItem
            dragViewModel.sharePhotoItem = shareService.sharePhotoItem
            dragViewModel.convertToFramedPhoto = convertToFramedPhoto
            
            // Blinking animation now starts after splash screen in .task
            
            // Cache system removed - no prefill needed
            
            // Notification prompt now happens after first photo is added
        }

        .alert(alertTitle, isPresented: $showEnjoymentAlert) {
            Button("Dismiss") {
                // User declined, clear any pending time travel
                hasPendingTimeTravel = false
            }
            Button("Yes", role: .cancel) {
                requestNotificationPermission()
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: dateSelectionViewModel.selectedDate) { oldDate, newDate in
            print("🔍 DEBUG: Date selection changed from \(oldDate) to \(newDate)")
            photoItemsViewModel.handleDateChange(newDate)
        }
        .onChange(of: photoItemsViewModel.photoItems.count) { oldCount, newCount in
            // Show notification prompt after first photo is added
            if FeatureFlags.shared.showAppLaunchNotificationPrompt 
                && !hasShownAppLaunchNotificationPrompt 
                && newCount > 0 {
                hasShownAppLaunchNotificationPrompt = true
                // Small delay to let the photo render
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showNotificationAlert(title: "Get Nostalgia Reminders", message: "get recaps from the past weeks of your life")
                }
            }
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
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    if status == .authorized || status == .limited {
                        self.photoItemsViewModel.fetchAndAddRandomPhoto(photoViewModel: self.photoViewModel, soundService: self.soundService)
                    }
                }
            }
        case .authorized, .limited:
            photoItemsViewModel.fetchAndAddRandomPhoto(photoViewModel: photoViewModel, soundService: soundService)
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
    
    private func handleScreenTap() {
        // Play click sound
        soundService.playSound(.click)
        
        // Hide the instruction text on first tap
        if !hasBeenTapped {
            hasBeenTapped = true
        }
        
        // Add photo directly on any tap
        if !photoItemsViewModel.isLoading {
            print("Screen tapped! Adding photo...")
            photoItemsViewModel.addTestPhotoItem(backgroundRemover: photoViewModel.backgroundRemover, soundService: soundService, dateSelection: dateSelectionViewModel, photoMode: photoModeManager.currentMode) { success in
                print("Photo added via screen tap: \(success)")
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
    
    private func startTopTextCycle() {
        let possibleTexts = AppConstants.cyclingTexts
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // Fade out
            withAnimation(.easeInOut(duration: 0.65)) {
                topTextOpacity = 0.0
            }
            
            // Change text and fade back in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                topText = possibleTexts.randomElement() ?? "this is not an app"
                withAnimation(.easeInOut(duration: 0.65)) {
                    topTextOpacity = 1.0
                }
            }
        }
    }
    

    private func showTravelMessage() {
        // Navigate to one day before current selected date
        dateSelectionViewModel.navigateToOneDayAgo()
        
        // Show overlay
        showTravelOverlay = true
        
        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showTravelOverlay = false
            }
        }
    }
    
    private func handleRewindAction() {
        // If notification requirement is disabled, do rewind immediately
        if !FeatureFlags.shared.requireNotificationForRewind {
            soundService.playSound(.timetravel)
            showTravelMessage()
            return
        }
        
        // Check if notifications are already authorized
        let permissionState = OneSignal.Notifications.permission
        if permissionState == true {
            // Notifications approved, do time travel immediately
            soundService.playSound(.timetravel)
            showTravelMessage()
        } else {
            // Notifications not approved, show alert first
            hasPendingTimeTravel = true
            showNotificationAlert(title: "Enable Push Notifications", message: "Unlock Rewind by approving notifications")
        }
    }
    
    private func showNotificationAlert(title: String, message: String) {
        // Check if notifications are already authorized
        let permissionState = OneSignal.Notifications.permission
        if permissionState != true {
            alertTitle = title
            alertMessage = message
            showEnjoymentAlert = true
        }
    }
    
    private func checkAndShowEnjoymentAlert() {
        // Check if notifications are already authorized
        let permissionState = OneSignal.Notifications.permission
        if permissionState != true {
            showEnjoymentAlert = true
        }
    }
    
    private func requestNotificationPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
            DispatchQueue.main.async {
                if accepted && hasPendingTimeTravel {
                    // User approved notifications and we have pending time travel
                    soundService.playSound(.timetravel)
                    showTravelMessage()
                    hasPendingTimeTravel = false
                }
            }
        }, fallbackToSettings: false)
    }
    
    private func toggleTurtleMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTurtleMode.toggle()
        }
        
        // Always play click sound first for immediate feedback
        soundService.playSound(.click)
        
        // If entering turtle mode, play japan3 after a short delay
        if isTurtleMode {
            soundService.playSound(.japan3, delay: 0.3)
        }
    }

}





#Preview {
    RandomPhotoView()
}
