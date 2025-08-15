//
//  bubuview.swift
//  kawaii
//
//  Created by ai on 8/11/25.
//

import SwiftUI
import Foundation
import SpriteKit
import CoreMotion

// Global scale factor to enlarge or shrink dog and related physics visuals in one place.
private let dogScale: CGFloat = 1.6

enum PendantMode {
	case bubu
	case customImage(String)
}

struct BallChainBead: View {
	var body: some View {
		ZStack {
			// Main metal ball
			Circle()
				.fill(
					LinearGradient(
						colors: [
							Color(red: 0.75, green: 0.75, blue: 0.8),
							Color(red: 0.9, green: 0.9, blue: 0.95),
							Color(red: 0.6, green: 0.6, blue: 0.65)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 8, height: 8)
				.shadow(color: .black.opacity(0.4), radius: 1, x: 0.5, y: 0.5)
		}
	}
}

struct ConnectingWire: View {
	var body: some View {
		Rectangle()
			.fill(Color(red: 0.7, green: 0.7, blue: 0.75))
			.frame(width: 3, height: 1)
	}
}

class ChainPhysicsScene: SKScene, ObservableObject {
	private var motionManager = CMMotionManager()
	@Published var beadNodes: [SKSpriteNode] = []
	@Published var pendantNode: SKSpriteNode?
	private let beadCount = 32
	private var updateTimer: Timer?
	private var bounceTimer: Timer?
	private var bouncePhase: Double = 0
	
	override func didMove(to view: SKView) {
		setupPhysics()
		createChain()
		createPendant()
		startMotionUpdates()
		startPositionUpdates()
		startBounceAnimation()
	}
	
	private func setupPhysics() {
		physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
		physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
	}
	
	private func createChain() {
		let startX = size.width * 0.1
		let endX = size.width * 0.9
		let topY = size.height - 50  // Start from top
		let controlY = size.height * 0.75  // Bottom control point - only 50% depth
		let centerX = size.width / 2
		
		// Create beads along bezier curve
		for i in 0..<beadCount {
			let t = CGFloat(i) / CGFloat(beadCount - 1)
			
			// Quadratic bezier calculation
			let x = pow(1-t, 2) * startX + 2*(1-t)*t*centerX + pow(t, 2) * endX
			let y = pow(1-t, 2) * topY + 2*(1-t)*t*controlY + pow(t, 2) * topY
			
			// Create bead physics body
			let bead = SKSpriteNode(color: .gray, size: CGSize(width: 8, height: 8))
			bead.position = CGPoint(x: x, y: y)
			bead.physicsBody = SKPhysicsBody(circleOfRadius: 4)
			bead.physicsBody?.isDynamic = (i == 0 || i == beadCount - 1) ? false : true  // Fix endpoints
			bead.physicsBody?.mass = 0.1
			bead.physicsBody?.friction = 0.2
			bead.physicsBody?.restitution = 0.1
			
			addChild(bead)
			beadNodes.append(bead)
			
			// Connect to previous bead with distance constraint
			if i > 0 {
				let prevBead = beadNodes[i-1]
				let distance = sqrt(pow(x - prevBead.position.x, 2) + pow(y - prevBead.position.y, 2))
				
				let joint = SKPhysicsJointLimit.joint(
					withBodyA: prevBead.physicsBody!,
					bodyB: bead.physicsBody!,
					anchorA: prevBead.position,  // Use actual world positions
					anchorB: bead.position       // Not zero!
				)
				joint.maxLength = distance * 1.05  // Small stretch allowance
				physicsWorld.add(joint)
			}
		}
	}
	
	private func createPendant() {
		// Find middle bead (bottom of U)
		let middleIndex = beadCount / 2
		let middleBead = beadNodes[middleIndex]
		
		// Create pendant (scaled)
		let pendantSize = CGSize(width: 40 * dogScale, height: 40 * dogScale)
		let pendant = SKSpriteNode(color: .clear, size: pendantSize)
		pendant.isHidden = true // Hide visual; physics body remains active
		pendant.position = CGPoint(x: middleBead.position.x, y: middleBead.position.y - 20 * dogScale)
		pendant.physicsBody = SKPhysicsBody(rectangleOf: pendantSize)
		pendant.physicsBody?.mass = 0.2  // Lighter so it doesn't drag chain down
		pendant.physicsBody?.friction = 0.1
		pendant.physicsBody?.restitution = 0.2
		
		addChild(pendant)
		pendantNode = pendant
		
		// Connect pendant to middle bead with limited distance
		let joint = SKPhysicsJointLimit.joint(
			withBodyA: middleBead.physicsBody!,
			bodyB: pendant.physicsBody!,
			anchorA: middleBead.position,   // Use actual positions
			anchorB: pendant.position      // Not zero!
		)
		joint.maxLength = 20.0 * dogScale  // Scaled pendant chain length
		physicsWorld.add(joint)
	}
	
	private func startMotionUpdates() {
		guard motionManager.isDeviceMotionAvailable else { return }
		
		motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
		motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
			guard let motion = motion, let self = self else { return }
			
			// Convert device orientation to gravity vector
			let gravity = motion.gravity
			let deviceGravityVector = CGVector(
				dx: gravity.x * 9.8,
				dy: gravity.y * 9.8
			)
			
			// Combine device motion with automatic bounce
			let bounceX = sin(self.bouncePhase) * 3.0
			let bounceY = cos(self.bouncePhase * 1.3) * 2.0
			
			// Rotate gravity 180° to match the upside-down UI
			let finalGravity = CGVector(
				dx: deviceGravityVector.dx + bounceX,
				dy: deviceGravityVector.dy + bounceY
			)

			let adjustedGravity = CGVector(
				dx: -finalGravity.dx,
				dy: -finalGravity.dy
			)

			self.physicsWorld.gravity = adjustedGravity
		}
	}
	
	private func startPositionUpdates() {
		updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
			DispatchQueue.main.async {
				self?.objectWillChange.send()
			}
		}
	}
	
	private func startBounceAnimation() {
		bounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			self.bouncePhase += 0.08  // Controls bounce speed
			
			// Add random impulses occasionally for more liveliness
			if Int.random(in: 0...300) == 1 {
				let randomForce = CGVector(
					dx: Double.random(in: -15...15),
					dy: Double.random(in: 5...25)
				)
				self.pendantNode?.physicsBody?.applyImpulse(randomForce)
			}
		}
	}
	
	deinit {
		motionManager.stopDeviceMotionUpdates()
		updateTimer?.invalidate()
		bounceTimer?.invalidate()
	}
}

struct bubuview: View {
	let pendantMode: PendantMode
	@StateObject private var physicsScene = ChainPhysicsScene()
	
	init(pendantMode: PendantMode = .bubu) {
//	init(pendantMode: PendantMode = .customImage("turtle")) {
		self.pendantMode = pendantMode
	}
	
	var body: some View {
		ZStack {
			// Background
			Color.black.opacity(0.05)
				.ignoresSafeArea()
			
			// Physics-enabled chain
			GeometryReader { geometry in
				ZStack {
					// SpriteKit physics scene (invisible beads)
					SpriteView(scene: configureScene(geometry: geometry))
						.ignoresSafeArea()
					
					// Visual overlay - sync with physics positions
					ChainVisualOverlay(scene: physicsScene, geometry: geometry, pendantMode: pendantMode)
				}
			}
			.rotationEffect(.degrees(180))
			.ignoresSafeArea()
		}
	}
	
	private func configureScene(geometry: GeometryProxy) -> ChainPhysicsScene {
		physicsScene.size = CGSize(width: geometry.size.width, height: geometry.size.height)
		physicsScene.scaleMode = .resizeFill
		return physicsScene
	}
}

struct ChainVisualOverlay: View {
	@ObservedObject var scene: ChainPhysicsScene
	let geometry: GeometryProxy
	let pendantMode: PendantMode
	@State private var mouthOpen: Bool = false
	@State private var bottomOffset: CGFloat = 0 // controls jaw drop distance
	
	var body: some View {
		ZStack {
			// Visual beads synced with physics
			ForEach(Array(scene.beadNodes.enumerated()), id: \.offset) { index, bead in
				BallChainBead()
					.position(x: bead.position.x, y: geometry.size.height - bead.position.y)
			}
			
			// Visual pendant synced with physics
			// New pendant anchored to the middle (bottom-most) bead
			if !scene.beadNodes.isEmpty {
				Group {
					switch pendantMode {
					case .bubu:
						BubuPendant(mouthOpen: mouthOpen, bottomOffset: bottomOffset)
							.onTapGesture {
								withAnimation(.easeInOut(duration: 0.25)) {
									mouthOpen.toggle()
									let openGap: CGFloat = 42 * dogScale
									bottomOffset = mouthOpen ? openGap : 0
								}
							}
					case .customImage(let imageName):
						CustomImagePendant(imageName: imageName)
					}
				}
				.position(
					x: scene.beadNodes[scene.beadNodes.count / 2].position.x,
					y: geometry.size.height - scene.beadNodes[scene.beadNodes.count / 2].position.y + 180 * dogScale
				)
			}
			
			VStack {
				Spacer()
				Text("dangertesting.com")
					.padding(.bottom, 50)
					.foregroundStyle(.white)
			}
			
		}
	}
}

struct BubuPendant: View {
	let mouthOpen: Bool
	let bottomOffset: CGFloat
	
	var body: some View {
		ZStack(alignment: .center) {
			VStack(spacing: -72 * dogScale) {
				Image("bigbubu_top")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 250 * dogScale, height: 273 * dogScale)
					.zIndex(1)
				
				Image("bigbubu_bottom")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 250 * dogScale, height: 227 * dogScale)
					.offset(y: bottomOffset)
					.zIndex(0)
			}
			
			Text("Recording...")
				.font(.caption)
				.bold()
				.foregroundColor(.red)
				.opacity(mouthOpen ? 1 : 0)
				.zIndex(1)
				.offset(y: bottomOffset + 25 * dogScale)

			RecordingView()
				.frame(width: 240 * dogScale, height: 60 * dogScale)
				.opacity(mouthOpen ? 1 : 0)
				.zIndex(-1)
				.offset(y: bottomOffset - 25 * dogScale)
		}
	}
}

struct CustomImagePendant: View {
	let imageName: String
	
	var body: some View {
		Image(imageName)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.background(Color.clear)
	}
}

struct Triangle: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: CGPoint(x: rect.midX, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
		return path
	}
}

struct Arc: Shape {
	let startAngle: Double
	let endAngle: Double
	
	func path(in rect: CGRect) -> Path {
		var path = Path()
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = min(rect.width, rect.height) / 2
		
		path.addArc(
			center: center,
			radius: radius,
			startAngle: .degrees(startAngle),
			endAngle: .degrees(endAngle),
			clockwise: false
		)
		return path
	}
}

#Preview {
	bubuview()
}
