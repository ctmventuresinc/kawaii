//
//  dogview.swift
//  kawaii
//
//  Created by ai on 8/11/25.
//

import SwiftUI

// MARK: - Constants
private let canvasSize: CGFloat = 1200
private let pupilRadius: CGFloat = 0.026 // 2.6% of width
private let jawMaxDegrees: CGFloat = 22
private let jawDropOffset: CGFloat = 4

// MARK: - Eye Positions (normalized in 1200x1200 space)
private let leftEyeCenter = CGPoint(x: 0.42, y: 0.45)
private let rightEyeCenter = CGPoint(x: 0.58, y: 0.45)

struct MonsterView: View {
    // MARK: - State
    @State private var internalEyeTarget: CGPoint = CGPoint(x: 0.5, y: 0.45)
    @State private var internalMouthOpen: CGFloat = 0
    @State private var isBlinking: Bool = false
    @State private var breathingScale: CGFloat = 1.0
    
    // MARK: - Bindings
    private let eyeTargetBinding: Binding<CGPoint>?
    private let mouthOpenBinding: Binding<CGFloat>?
    
    // MARK: - Computed Properties
    private var eyeTarget: CGPoint {
        eyeTargetBinding?.wrappedValue ?? internalEyeTarget
    }
    
    private var mouthOpen: CGFloat {
        mouthOpenBinding?.wrappedValue ?? internalMouthOpen
    }
    
    // MARK: - Initializer
    init(eyeTarget: Binding<CGPoint>? = nil, mouthOpen: Binding<CGFloat>? = nil) {
        self.eyeTargetBinding = eyeTarget
        self.mouthOpenBinding = mouthOpen
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / canvasSize, geometry.size.height / canvasSize)
            let scaledSize = canvasSize * scale
            
            ZStack {
                // Layer 1: Body (head + suit, no eyes/mouth)
                Image("body")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                // Layer 2: Eye whites
                Image("eye_left_white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Image("eye_right_white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                // Layer 3: Pupils (with tracking)
                if !isBlinking {
                    Image("pupil_left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .offset(leftPupilOffset(scale: scale))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: eyeTarget)
                    
                    Image("pupil_right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .offset(rightPupilOffset(scale: scale))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: eyeTarget)
                }
                
                // Layer 4: Mouth bottom (jaw - animated)
                Image("mouth_bottom")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(jawMaxDegrees * mouthOpen), anchor: .top)
                    .offset(y: jawDropOffset * mouthOpen * scale)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: mouthOpen)
                
                // Layer 5: Mouth top (fixed)
                Image("mouth_top")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(width: scaledSize, height: scaledSize)
            .scaleEffect(breathingScale)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let normalizedPoint = CGPoint(
                            x: value.location.x / geometry.size.width,
                            y: value.location.y / geometry.size.height
                        )
                        updateEyeTarget(normalizedPoint)
                    }
            )
            .onTapGesture {
                toggleMouth()
            }
        }
        .onAppear {
            startBreathing()
        }
    }
    
    // MARK: - Pupil Calculations
    private func leftPupilOffset(scale: CGFloat) -> CGSize {
        let eyeCenter = CGPoint(
            x: leftEyeCenter.x * canvasSize * scale,
            y: leftEyeCenter.y * canvasSize * scale
        )
        let targetPoint = CGPoint(
            x: eyeTarget.x * canvasSize * scale,
            y: eyeTarget.y * canvasSize * scale
        )
        return clampedOffset(from: targetPoint, center: eyeCenter, radius: pupilRadius * canvasSize * scale)
    }
    
    private func rightPupilOffset(scale: CGFloat) -> CGSize {
        let eyeCenter = CGPoint(
            x: rightEyeCenter.x * canvasSize * scale,
            y: rightEyeCenter.y * canvasSize * scale
        )
        let targetPoint = CGPoint(
            x: eyeTarget.x * canvasSize * scale,
            y: eyeTarget.y * canvasSize * scale
        )
        return clampedOffset(from: targetPoint, center: eyeCenter, radius: pupilRadius * canvasSize * scale)
    }
    
    private func clampedOffset(from target: CGPoint, center: CGPoint, radius: CGFloat) -> CGSize {
        let dx = target.x - center.x
        let dy = target.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance <= radius {
            return CGSize(width: dx, height: dy)
        } else {
            let scale = radius / distance
            return CGSize(width: dx * scale, height: dy * scale)
        }
    }
    
    // MARK: - Actions
    private func updateEyeTarget(_ point: CGPoint) {
        if let binding = eyeTargetBinding {
            binding.wrappedValue = point
        } else {
            internalEyeTarget = point
        }
    }
    
    private func toggleMouth() {
        let newValue: CGFloat = mouthOpen > 0.5 ? 0 : 1
        if let binding = mouthOpenBinding {
            binding.wrappedValue = newValue
        } else {
            internalMouthOpen = newValue
        }
    }
    
    private func startBreathing() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                breathingScale = breathingScale == 1.0 ? 1.005 : 1.0
            }
        }
    }
    
    // MARK: - Public API
    func look(at point: CGPoint) {
        updateEyeTarget(point)
    }
    
    func setMouth(open: CGFloat) {
        let clampedValue = max(0, min(1, open))
        if let binding = mouthOpenBinding {
            binding.wrappedValue = clampedValue
        } else {
            internalMouthOpen = clampedValue
        }
    }
    
    func blink() {
        withAnimation(.easeInOut(duration: 0.06)) {
            isBlinking = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.06)) {
                isBlinking = false
            }
        }
    }
}

// MARK: - Preview
struct dogview: View {
    @State private var eyeTarget = CGPoint(x: 0.5, y: 0.45)
    @State private var mouthOpen: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            VStack {
                MonsterView(eyeTarget: $eyeTarget, mouthOpen: $mouthOpen)
                    .frame(maxWidth: 400, maxHeight: 400)
                
                HStack {
                    Button("Blink") {
                        // Create a reference to call blink - this is a limitation of the current setup
                    }
                    
                    Button("Random Look") {
                        eyeTarget = CGPoint(
                            x: Double.random(in: 0.2...0.8),
                            y: Double.random(in: 0.3...0.6)
                        )
                    }
                    
                    Button("Toggle Mouth") {
                        withAnimation {
                            mouthOpen = mouthOpen > 0.5 ? 0 : 1
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    dogview()
}
