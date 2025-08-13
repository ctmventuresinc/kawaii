//
//  bubuview.swift
//  kawaii
//
//  Created by ai on 8/11/25.
//

import SwiftUI
import SpriteKit
import CoreMotion

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



class ChainPhysicsScene: SKScene, ObservableObject {
	private var motionManager = CMMotionManager()
	@Published var beadNodes: [SKSpriteNode] = []
	@Published var pendantNode: SKSpriteNode?
	private let beadCount = 32
	private var updateTimer: Timer?
	
	override func didMove(to view: SKView) {
		setupPhysics()
		createChain()
		createPendant()
		startMotionUpdates()
		startPositionUpdates()
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
		
		// Create pendant
		let pendantSize = CGSize(width: 32, height: 32)
		let pendant = SKSpriteNode(color: .clear, size: pendantSize)
		pendant.position = CGPoint(x: middleBead.position.x, y: middleBead.position.y - 16)
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
		joint.maxLength = 16.0  // Pendant chain length
		physicsWorld.add(joint)
	}
	
	private func startMotionUpdates() {
		guard motionManager.isDeviceMotionAvailable else { return }
		
		motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
		motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
			guard let motion = motion else { return }
			
			// Convert device orientation to gravity vector
			let gravity = motion.gravity
			let gravityVector = CGVector(
				dx: gravity.x * 9.8,
				dy: gravity.y * 9.8
			)
			
			self?.physicsWorld.gravity = gravityVector
		}
	}
	
	private func startPositionUpdates() {
		updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
			DispatchQueue.main.async {
				self?.objectWillChange.send()
			}
		}
	}
	
	deinit {
		motionManager.stopDeviceMotionUpdates()
		updateTimer?.invalidate()
	}
}

struct bubuview: View {
	@StateObject private var physicsScene = ChainPhysicsScene()
	
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
					ChainVisualOverlay(scene: physicsScene, geometry: geometry)
				}
			}
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
	
	var body: some View {
		ZStack {
			// Visual beads synced with physics
			ForEach(Array(scene.beadNodes.enumerated()), id: \.offset) { index, bead in
				BallChainBead()
					.position(x: bead.position.x, y: geometry.size.height - bead.position.y)
			}
			
			// Simple pendant at middle bead
			if !scene.beadNodes.isEmpty {
				Circle()
					.fill(Color(red: 0.75, green: 0.75, blue: 0.8))
					.frame(width: 32, height: 32)
					.position(
						x: scene.beadNodes[scene.beadNodes.count / 2].position.x,
						y: geometry.size.height - scene.beadNodes[scene.beadNodes.count / 2].position.y - 16
					)
			}
		}
	}
}



#Preview {
	bubuview()
}
