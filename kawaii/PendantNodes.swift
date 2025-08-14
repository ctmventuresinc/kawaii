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
final class CustomImagePendantNode: SKSpriteNode, PendantPhysicsNode {

    init(imageName: String, scale: CGFloat) {
        let tex = SKTexture(imageNamed: imageName)
        super.init(texture: tex, color: .clear, size: tex.size())
        setScale(scale)

        physicsBody = SKPhysicsBody(texture: tex, size: tex.size())
        physicsBody?.mass = 0.2
        physicsBody?.friction = 0.1
        physicsBody?.restitution = 0.2
    }

    required init?(coder: NSCoder) { fatalError() }

    func handleTap() { /* nothing for now */ }
}
