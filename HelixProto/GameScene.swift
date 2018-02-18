//
//  GameScene.swift
//  HelixProto
//
//  Created by Alexander Schülke on 10.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioKit

class GameScene: SKScene {
    
    var gameSceneDelegate: GameDelegate?
    
    private var background = SKSpriteNode(imageNamed: "alt_background")
    // The parts represent the individual pieces of the DNA. Each part can hold a tone.
    private var parts: [SKSpriteNode] = []
    // The bases that are available for the user on the right of the screen
    private var bases: [Int:SKSpriteNode] = [:]
    // All the bases that were assigned to the DNA
    private var basesOnDna: [SKSpriteNode] = []
    // All DNA parts are listed here with according bases
    private var BasesByParts: [(SKSpriteNode, SKSpriteNode?)] = []
    
    private let audioManager = AudioManager()
    
    // For dragging bases
    private let panRecognizer = UIPanGestureRecognizer()
    // Currently moved base
    private var currentBase: SKSpriteNode?
    private var currentPart: SKSpriteNode?
    private var originalBasePosition: CGPoint?

    private var selectionFrame: SelectionFrame?
    
    private var currentSequencerPosition = -1
    
    override init(size: CGSize) {
        // Create the one side of the DNA string.
        for index in 0...11 {
            let part = SKSpriteNode(imageNamed: "alt_stridepart")
            part.zPosition = 0
            part.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            parts.append(part)
            BasesByParts.append((part, nil))
        }
        
        // Create the 4 bases available for the user
        bases[0] = SKSpriteNode(imageNamed: "alt_base1")
        bases[1] = SKSpriteNode(imageNamed: "alt_base2")
        bases[2] = SKSpriteNode(imageNamed: "alt_base3")
        bases[3] = SKSpriteNode(imageNamed: "alt_base4")

        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initial setup
    override func didMove(to view: SKView) {
        
        // Create background
        backgroundColor = SKColor.black
        background.zPosition = -1
        addChild(background)
        
        // Manage background
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.size = self.frame.size
        
        // Build the dna string, part by part
        for (index, part) in parts.enumerated() {
            addChild(part)
            part.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height - part.frame.size.height * CGFloat(index))
            
        }
        
        // Position the 4 bases
        for (index, base) in bases {
            addChild(base)
            base.anchorPoint = CGPoint(x: 0, y: 0.5)
            base.zPosition = 1
            base.name = "tone\(index+1)"
            let overallHeight = base.frame.size.height * CGFloat(bases.count)
            base.position = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (base.frame.size.height * 2 * CGFloat(index)))
        }
        
        let playButton = SKSpriteNode(imageNamed: "playButton")
        playButton.name = "playButton"
        addChild(playButton)
        playButton.zPosition = 99
        playButton.position = CGPoint(x: self.frame.size.width / 1.58, y: self.frame.size.height / 7.7)
        playButton.scale(to: CGSize(width: playButton.size.width * CGFloat(1.5), height: playButton.size.height * CGFloat(1.5)))
        
        
        
        panRecognizer.addTarget(self, action: #selector(GameScene.drag(_:)))
        self.view!.addGestureRecognizer(panRecognizer)

        audioManager.delegate = self
        
//        decodeBases(data: ["", "tone1", "", "", "tone3", "", "", "tone4", "", "", "", ""])
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        let newSequencerPosition = Int(audioManager.sequencer.currentRelativePosition.beats)

        if currentSequencerPosition != newSequencerPosition && audioManager.sequencer.isPlaying {
            currentSequencerPosition = newSequencerPosition
            audioManager.updateLoop()
            print(newSequencerPosition)
            highlightBase()
        }
       
    }
    
    // Gets called by the UIPanGestureRecognizer.
    // Describes the behaviour while being dragged and what should happen at the end of a drag.
    @objc func drag(_ gestureRecognizer: UIPanGestureRecognizer) {
        // While dragging update base's position to current finger position.
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let translation = gestureRecognizer.translation(in: self.view)
            
            if let currentPart = currentPart {
                for part in parts {
                    part.position = CGPoint(x: part.position.x, y: part.position.y - translation.y*2)
                }
                gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
            }
            
            guard let currentBase = currentBase else {
                return
            }
            if let nearest = getNearestPart() {
                if let selectionFrame = self.selectionFrame {
                    if nearest != selectionFrame.accordingPart {
                        if !isPartEmpty(nearest) {
                            removeSelectionFrame()
                        }
                        else {
                            selectionFrame.position = CGPoint(x: 0, y: nearest.position.y - nearest.frame.height / 2)
                        }
                    }
                }
                else if isPartEmpty(nearest){
                    selectionFrame = SelectionFrame(rectOfSize: CGSize(width: self.frame.size.width, height: nearest.frame.height))
                    selectionFrame!.position = CGPoint(x: 0, y: nearest.position.y - nearest.frame.height / 2)
                    addChild(selectionFrame!)
                }
            }
            
            currentBase.position = CGPoint(x: currentBase.position.x + translation.x*2, y: currentBase.position.y - translation.y*2)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        }
            // End of drag, decide wether to snap to the stride or return to original position
        else if gestureRecognizer.state == .ended {
            if let currentBase = currentBase {
                if checkIfDeleted(currentBase) {
                    return
                }
                if let nearest = getNearestPart() {
                    // Only assign base to position if base is near enough and part doesn't hold a base yet
                    if isPartEmpty(nearest){
                        let newPosition = CGPoint(x: nearest.position.x + currentBase.frame.width / 24, y: nearest.position.y)
                        let snap = SKAction.move(to: newPosition, duration: 0.1)
                        currentBase.run(snap)
                        basesOnDna.append(currentBase)
                        for (index, tuple) in BasesByParts.enumerated() {
                            if tuple.0 == nearest {
                                cleanOldParts(from: currentBase)
                                BasesByParts[index] = (nearest, currentBase)
                                gameSceneDelegate?.triggerSendData()
                            }
                        }
                        // Get next base of same type
                        reloadSample(for: currentBase)
                        removeSelectionFrame()
                        return
                    }
                }
                // Move bases back to original position, because it could not snap with any DNA slot
                if let originalBasePosition = self.originalBasePosition {
                    removeSelectionFrame()
                    let snapBack = SKAction.move(to: originalBasePosition, duration: 0.3)
                    currentBase.run(snapBack)
                }
            }
        }
    }
    
    // Return true when given part doesn't hold a base.
    func isPartEmpty(_ part: SKSpriteNode) -> Bool {
        for (index, _) in BasesByParts.enumerated() {
            if part == BasesByParts[index].0 && BasesByParts[index].1 == nil {
                return true
            }
        }
        return false
    }
    
    func cleanOldParts(from base: SKSpriteNode) {
        for (index, tuple) in BasesByParts.enumerated() {
            if base == BasesByParts[index].1 {
                // Clean the part from base by reassigning nil as base
                BasesByParts[index] = (tuple.0, nil)
                return
            }
        }
    }
    
    func checkIfDeleted(_ base: SKSpriteNode) -> Bool{
        let oldAnchorPoint = base.anchorPoint
        base.anchorPoint = CGPoint(x: 0, y: base.anchorPoint.y)
        let leftMostPoint = base.position
        base.anchorPoint = oldAnchorPoint
        if (leftMostPoint.x < parts.first!.position.x - parts.first!.frame.size.width * 2) {
            cleanOldParts(from: base)
            basesOnDna.remove(at: basesOnDna.index(of: base)!)
            let leaveScreen = SKAction.moveTo(x: base.position.x - base.frame.size.width * 2, duration: 0.5)
            let remove = SKAction.run {
                base.removeFromParent()
            }
            let sequence = SKAction.sequence([leaveScreen, remove])
            base.run(sequence)
            reloadSample(for: base)
            return true
        }
        return false
    }
    
    // In this method it is set which base the user wants to move right now,
    // which means to set 'currentBase', so the drag method can work properly.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let nodes = self.nodes(at: location)
            if nodes.first is SKSpriteNode {
                let node = nodes.first as! SKSpriteNode
                if parts.contains(node) {
                    currentPart = node
                } else {
                    currentPart = nil
                }
                if let name = node.name {
                    if name == "playButton" {
                        node.playPressedAnimation()
                        node.name = "stopButton"
                        audioManager.play()
                    }
                    else if name == "stopButton"{

                        node.playPressedAnimation()
                        node.name = "playButton"
                        audioManager.stop()
                    }
                }
                if bases.values.contains(node) || basesOnDna.contains(node){
                    if let name = node.name {
                        audioManager.playSample(baseName: name)
                    }
                    originalBasePosition = node.position
                    currentBase = node
                } else {
                    currentBase = nil
                }
            } else {
                currentBase = nil
            }
        }
    }
    
    
    // This method checks all DNA parts to return the nearest one to the currentBase
    private func getNearestPart() -> SKSpriteNode? {
        if let currentBase = currentBase {
            var nearest: (part: SKSpriteNode, distance: CGFloat) = (parts.first!, parts.first!.position.distance(point: currentBase.position))
            
            for part in parts {
                let distance = part.position.distance(point: currentBase.position)
                if distance < nearest.distance {
                    nearest = (part, distance)
                }
            }
            return nearest.part
        }
        return nil
    }
    
    // Recreates a base for the user, so one base can be assigned to the DNA multiple times
    private func reloadSample(for base: SKSpriteNode) {
        if let index = bases.values.index(of: base) {
            let position = bases.keys[index]
            bases.removeValue(forKey: position)
            var newBase: SKSpriteNode
            switch position {
            case 0:
                newBase = SKSpriteNode(imageNamed: "alt_base1")
            case 1:
                newBase = SKSpriteNode(imageNamed: "alt_base2")
            case 2:
                newBase = SKSpriteNode(imageNamed: "alt_base3")
            case 3:
                newBase = SKSpriteNode(imageNamed: "alt_base4")
            default:
                newBase = SKSpriteNode(imageNamed: "alt_base1")
            }
            bases[position] = newBase
            newBase.name = "tone\(position+1)"
            addChild(newBase)
            newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
            newBase.zPosition = 1
            let overallHeight = newBase.frame.size.height * CGFloat(bases.count)
            newBase.position = CGPoint(x: self.frame.size.width, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 2 * CGFloat(position)))
            let finalPos = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 2 * CGFloat(position)))
            
            let appear = SKAction.move(to: finalPos, duration: 0.5)
            newBase.run(appear)
        }
    }
    
    func removeSelectionFrame() {
        if let selectionFrame = selectionFrame {
            selectionFrame.removeFromParent()
            self.selectionFrame = nil
        }
    }
    
    func highlightBase() {
        
        var newSequencerPosition = Int(audioManager.sequencer.currentRelativePosition.beats)

        
        let currentPart = parts[newSequencerPosition]

        for (part, base) in BasesByParts {
            if part == currentPart {
                if let base = base {
                    base.alpha = 0.7
                }
            }
            else {
                if let base = base {
                    base.alpha = 1
                }
            }
        }
    }
    
    func encodeBases() -> [String] {
        var resultArray: [String] = []
        for (index, value) in BasesByParts.enumerated() {
            if let base = value.1 {
                if let name = base.name {
                    resultArray.append(name)
                }
            }
            else {
                resultArray.append("")
            }
        }
        return resultArray
    }
    
    func decodeBases(data: [String]) {
        for (index, name) in data.enumerated() {
            if name == "" || !isPartEmpty(BasesByParts[index].0) {
                continue
            }
            else {
                var newBase: SKSpriteNode
                switch name {
                case "tone1":
                    newBase = SKSpriteNode(imageNamed: "alt_base1")
                case "tone2":
                    newBase = SKSpriteNode(imageNamed: "alt_base2")
                case "tone3":
                    newBase = SKSpriteNode(imageNamed: "alt_base3")
                case "tone4":
                    newBase = SKSpriteNode(imageNamed: "alt_base4")
                default:
                    newBase = SKSpriteNode(imageNamed: "alt_base1")
                }
                newBase.name = name
                addChild(newBase)
                newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
                newBase.zPosition = 1
                let s = "S"
                
                newBase.position = CGPoint(x: parts.first!.position.x  + newBase.frame.width / 24, y: parts[index].position.y)
                basesOnDna.append(newBase)
                BasesByParts[index] = (BasesByParts[index].0, newBase)
                
            }
        }
    }
    
}

extension GameScene : AudioManagerDelegate {
    
    public func getBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)] {
        return BasesByParts
    }
    
}

