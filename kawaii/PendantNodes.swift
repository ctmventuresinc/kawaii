//
//  PendantNodes.swift
//  kawaii
//
//  Created by ai on 8/14/25.
//

import SpriteKit

// A common protocol so the scene can treat every pendant the same way
protocol PendantPhysicsNode where Self: SKNode {
    /// Called by the scene when the user taps on the pendant.
    func handleTap()
}

/* ──────────────────────────────────────────────────────────────
   Bubu made from two child sprites so the mouth can open
   ────────────────────────────────────────────────────────────── */
final class BubuPendantNode: SKNode, PendantPhysicsNode {

    private let top: SKSpriteNode
    private let bottom: SKSpriteNode
    private let scale: CGFloat
    private var mouthOpen = false

    init(scale: CGFloat) {
        self.scale = scale

        top = SKSpriteNode(imageNamed: "bigbubu_top")
        bottom = SKSpriteNode(imageNamed: "bigbubu_bottom")
        super.init()

        // Scale the two images
        [top, bottom].forEach { node in
            node.setScale(scale)
            node.anchorPoint = CGPoint(x: 0.5, y: 1)      // hinge on the top edge
        }

        // Stack bottom 72 pt below the top (value taken from the SwiftUI view)
        bottom.position = CGPoint(x: 0, y: -72 * scale)

        addChild(top)
        addChild(bottom)

        // SpriteKit physics body on the container (this SKNode)
        physicsBody = SKPhysicsBody(rectangleOf: boundingSize)
        physicsBody?.mass = 0.2
        physicsBody?.friction = 0.1
        physicsBody?.restitution = 0.2
    }

    required init?(coder: NSCoder) { fatalError() }

    // Used by the scene when the user taps
    func handleTap() { toggleMouth() }

    // MARK: -- Private helpers
    private var boundingSize: CGSize {
        let width = top.size.width * scale
        let height = (top.size.height + bottom.size.height - 72) * scale
        return CGSize(width: width, height: height)
    }

    private func toggleMouth() {
        let delta = 42 * scale                         // 42 pt jaw drop
        let move = SKAction.moveBy(x: 0,
                                    y: mouthOpen ? -delta : delta,
                                    duration: 0.25)
        move.timingMode = .easeInEaseOut
        bottom.run(move)
        mouthOpen.toggle()
    }
}

/* ──────────────────────────────────────────────────────────────
   Generic custom-image pendant
   ────────────────────────────────────────────────────────────── */
final class CustomImagePendantNode: SKNode, PendantPhysicsNode {

    init(imageName: String, scale: CGFloat) {
        super.init()
        
        // Create reliable rectangular physics body - tall rectangle
        let physicsSize = CGSize(width: 100, height: 300)
        // Position physics body so it hangs DOWN from origin (0,0)
        physicsBody = SKPhysicsBody(
            rectangleOf: physicsSize,
            center: CGPoint(x: 0, y: -physicsSize.height / 2)
        )
        physicsBody?.mass = 0.2
        physicsBody?.friction = 0.1
        physicsBody?.restitution = 0.2
        
        // Add background color with top-center anchor so it hangs down like a pendant
        let backgroundNode = SKSpriteNode(color: .systemRed, size: physicsSize)
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)  // Top center anchor
        addChild(backgroundNode)
        
        // Add image as visual child on top, scaled to fit within physics bounds
        let tex = SKTexture(imageNamed: imageName)
        let imageNode = SKSpriteNode(texture: tex)
        
        // Calculate scale to fit image within physics boundaries
        let imageSize = tex.size()
        let maxDimension = max(imageSize.width, imageSize.height)
        let targetSize: CGFloat = 280 // Slightly smaller than physics height for padding
        let fitScale = targetSize / maxDimension
        
        imageNode.setScale(fitScale)
        imageNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)  // Match background anchor
        imageNode.zPosition = 1  // Put image in front of background
        addChild(imageNode)
    }

    required init?(coder: NSCoder) { fatalError() }

    func handleTap() { /* nothing for now */ }
}

/* ──────────────────────────────────────────────────────────────
   Two-part image pendant (like bigbubu_top + bigbubu_bottom)
   ────────────────────────────────────────────────────────────── */
final class TwoPartImagePendantNode: SKNode, PendantPhysicsNode {

    let topPart: SKNode  // Exposed for connecting to chain
    private let bottomPart: SKNode
    private var jawJoint: SKPhysicsJoint?

    init(topImageName: String, bottomImageName: String, scale: CGFloat) {
        topPart = SKNode()
        bottomPart = SKNode()
        super.init()
        
        // Create top part with physics body
        let topImage = SKSpriteNode(imageNamed: topImageName)
        let topSize = topImage.texture?.size() ?? CGSize.zero
        let topScale = (140.0 / max(topSize.width, topSize.height)) * scale  // Fit in half the frame
        topImage.setScale(topScale)
        topImage.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        topPart.addChild(topImage)
        topPart.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: topSize.width * topScale, height: topSize.height * topScale))
        topPart.physicsBody?.mass = 0.1
        topPart.physicsBody?.friction = 0.1
        topPart.physicsBody?.restitution = 0.2
        addChild(topPart)
        
        // Create bottom part with physics body  
        let bottomImage = SKSpriteNode(imageNamed: bottomImageName)
        let bottomSize = bottomImage.texture?.size() ?? CGSize.zero
        let bottomScale = (140.0 / max(bottomSize.width, bottomSize.height)) * scale
        bottomImage.setScale(bottomScale)
        bottomImage.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        bottomPart.addChild(bottomImage)
        bottomPart.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: bottomSize.width * bottomScale, height: bottomSize.height * bottomScale))
        bottomPart.physicsBody?.mass = 0.1
        bottomPart.physicsBody?.friction = 0.1  
        bottomPart.physicsBody?.restitution = 0.2
        
        // Position bottom part below top part
        bottomPart.position = CGPoint(x: 0, y: -(topSize.height * topScale))
        addChild(bottomPart)
        
        // Connect them with a pin joint at the jaw hinge point
        let hingePoint = CGPoint(x: 0, y: -(topSize.height * topScale))
        jawJoint = SKPhysicsJointPin.joint(
            withBodyA: topPart.physicsBody!,
            bodyB: bottomPart.physicsBody!,
            anchor: hingePoint
        )
        
        // We'll add this joint to the scene in a moment when we have access to physicsWorld
    }

    required init?(coder: NSCoder) { fatalError() }

    func handleTap() { 
        // Apply a small impulse to the jaw to make it swing
        let impulse = CGVector(dx: 0, dy: -20)
        bottomPart.physicsBody?.applyImpulse(impulse)
    }
    
    func addJointToWorld(_ physicsWorld: SKPhysicsWorld) {
        if let joint = jawJoint {
            physicsWorld.add(joint)
        }
    }
}
