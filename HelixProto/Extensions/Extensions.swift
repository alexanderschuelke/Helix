//
//  Extensions.swift
//  HelixProto
//
//  Created by Alexander Schülke on 11.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import Foundation
import SpriteKit

extension CGPoint {
    
    func distance(point: CGPoint) -> CGFloat {
        return abs(CGFloat(hypotf(Float(point.x - x), Float(point.y - y))))
    }
}

extension SKSpriteNode {

    var id: Int { return Int(arc4random_uniform(1000000)) }
    
    // Simple press animation
    public func playPressedAnimation() {
        let scale = SKAction.scale(to: CGSize(width: self.size.width / CGFloat(1.2), height: self.size.height / CGFloat(1.2)), duration: 0.1)
        let scaleBack = SKAction.scale(to: CGSize(width: self.size.width * CGFloat(1.0), height: self.size.height * CGFloat(1.0)), duration: 0.1)
        let changeSprite: SKAction
        if name! == "playButton" {
            changeSprite = SKAction.setTexture(SKTexture(imageNamed: "stopButton"))
        }
        else {
            changeSprite = SKAction.setTexture(SKTexture(imageNamed: "playButton"))
        }
        
        let sequence = SKAction.sequence([scale, scaleBack, changeSprite])
        self.run(sequence)
        
    }

}

