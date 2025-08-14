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

// Global scale factor to enlarge or shrink Labubu and related physics visuals in one place.
private let labubuScale: CGFloat = 1.6

enum PendantMode: Equatable {
	case bubu
	case customImage(String)
	case twoPartImage(String, String)  // topImage, bottomImage
}



class ChainPhysicsScene: SKScene {
	private var motionManager = CMMotionManager()
	private var beadNodes: [SKSpriteNode] = []
	private var pendantNode: (any PendantPhysicsNode)?
	private let beadCount = 32
	private var bounceTimer: Timer?
	private var bouncePhase: Double = 0
	private let pendantMode: PendantMode
	
	init(size: CGSize, pendantMode: PendantMode) {
		self.pendantMode = pendantMode
		super.init(size: size)
	}
	
	required init?(coder: NSCoder) { fatalError() }
	
	override func didMove(to view: SKView) {
		setupPhysics()
		createChain()
		createPendant()
		startMotionUpdates()
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
			
			// Create bead physics body with metallic appearance
			let bead = SKSpriteNode(color: .lightGray, size: CGSize(width: 8, height: 8))
			bead.position = CGPoint(x: x, y: y)
			bead.colorBlendFactor = 1.0  // Make sure color shows
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
		
		// Create pendant based on mode
		let node: SKNode
		switch pendantMode {
		case .bubu:
			// For now, use red rectangle for bubu too
			node = SKSpriteNode(color: .blue, size: CGSize(width: 100, height: 100))
			node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 100, height: 100))
		case .customImage(let name):
			node = CustomImagePendantNode(imageName: name, scale: labubuScale)
		case .twoPartImage(let topName, let bottomName):
			node = TwoPartImagePendantNode(topImageName: topName, bottomImageName: bottomName, scale: labubuScale)
		}
		
		node.physicsBody?.mass = 0.2
		node.physicsBody?.friction = 0.1
		node.physicsBody?.restitution = 0.2
		
		// Place the node directly at the supporting bead (no gap)
		node.position = middleBead.position
		
		addChild(node)
		pendantNode = node as? (any PendantPhysicsNode)  // Store if it's a PendantPhysicsNode
		
		// If it's a two-part pendant, add its internal joint to the physics world
		if let twoPartPendant = node as? TwoPartImagePendantNode {
			twoPartPendant.addJointToWorld(physicsWorld)
		}
		
		// Connect pendant to middle bead with zero-gap pin joint
		let pendantPhysicsBody: SKPhysicsBody
		if let twoPartPendant = node as? TwoPartImagePendantNode {
			// For two-part pendants, connect the top part to the chain
			pendantPhysicsBody = twoPartPendant.topPart.physicsBody!
		} else {
			// For single pendants, use the node's physics body
			pendantPhysicsBody = node.physicsBody!
		}
		
		let joint = SKPhysicsJointPin.joint(
			withBodyA: middleBead.physicsBody!,
			bodyB: pendantPhysicsBody,
			anchor: middleBead.position  // Same point for both bodies = zero gap
		)
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
			
			// Combine device motion with gentle automatic bounce
			let bounceX = sin(self.bouncePhase) * 1.0  // Reduced from 3.0
			let bounceY = cos(self.bouncePhase * 1.3) * 0.8  // Reduced from 2.0
			
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
	
	private func startBounceAnimation() {
		bounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			self.bouncePhase += 0.04  // Reduced from 0.08 - slower bounce
			
			// Add random impulses less frequently for more liveliness
			if Int.random(in: 0...600) == 1 {  // Reduced frequency from 300 to 600
				let randomForce = CGVector(
					dx: Double.random(in: -8...8),   // Reduced from -15...15
					dy: Double.random(in: 3...12)    // Reduced from 5...25
				)
				self.pendantNode?.physicsBody?.applyImpulse(randomForce)
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first,
			  let pendantNode else { return }
		
		let location = touch.location(in: self)
		if pendantNode.contains(location) {
			pendantNode.handleTap()
		}
	}
	
	deinit {
		motionManager.stopDeviceMotionUpdates()
		bounceTimer?.invalidate()
	}
}

struct bubuview: View {
	let pendantMode: PendantMode
	
	init(pendantMode: PendantMode = .twoPartImage("bigbubu_top", "bigbubu_bottom")) {
		self.pendantMode = pendantMode
	}
	
	var body: some View {
		GeometryReader { geometry in
			SpriteView(scene: {
				let scene = ChainPhysicsScene(
					size: geometry.size,
					pendantMode: pendantMode
				)
				scene.scaleMode = .resizeFill
				return scene
			}())
			.rotationEffect(.degrees(180))
			.ignoresSafeArea()
		}
	}
}

#Preview {
	bubuview()
}
