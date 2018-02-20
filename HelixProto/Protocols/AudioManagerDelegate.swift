//
//  AudioManagerDelegate.swift
//  HelixProto
//
//  Created by Alexander Schülke on 13.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import Foundation
import SpriteKit

protocol AudioManagerDelegate {
    
    func getBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)]
    func getPassiveBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)]
    func getParts() -> [SKSpriteNode]
}
