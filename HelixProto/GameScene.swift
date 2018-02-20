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
    
    enum side {
        case left
        case right
    }
    
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
    private var passiveBasesByParts: [(SKSpriteNode, SKSpriteNode?)] = []
    
    private var rightParts: [SKSpriteNode] = []
    private var rightBases: [Int:SKSpriteNode] = [:]
    private var rightBasesByParts: [(SKSpriteNode, SKSpriteNode?)] = []
    
    private var leftParts: [SKSpriteNode] = []
    private var leftBases: [Int:SKSpriteNode] = [:]
    private var leftBasesByParts: [(SKSpriteNode, SKSpriteNode?)] = []
    
    private let audioManager = AudioManager()
    
    // For dragging bases
    private let panRecognizer = UIPanGestureRecognizer()
    // Currently moved base
    private var currentBase: SKSpriteNode?
    private var currentPart: SKSpriteNode?
    private var scrolling: Bool = false
    private var originalBasePosition: CGPoint?

    private var selectionFrame: SelectionFrame?
    private var playButton: SKSpriteNode = SKSpriteNode(imageNamed: "playButton")
    private var currentSequencerPosition = -1
    private var currentSide: side = side.left
    
    override init(size: CGSize) {
        // Create the one side of the DNA string.
        for index in 0...11 {
            let part = SKSpriteNode(imageNamed: "circle_orange")
            part.zPosition = 3
            part.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            leftParts.append(part)
            leftBasesByParts.append((part, nil))
            
            let rightPart = SKSpriteNode(imageNamed: "circle_orange")
            rightPart.zPosition = 3
            rightPart.xScale = -1
            rightPart.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            rightParts.append(rightPart)
            rightBasesByParts.append((rightPart, nil))
        }
        
        // Create the 4 bases available for the user
        leftBases[0] = SKSpriteNode(imageNamed: "square_stride_pink")
        leftBases[1] = SKSpriteNode(imageNamed: "square_stride_orange")
        leftBases[2] = SKSpriteNode(imageNamed: "square_stride_light")
        leftBases[3] = SKSpriteNode(imageNamed: "square_stride_white")

        rightBases[0] = SKSpriteNode(imageNamed: "square_stride_pink")
        rightBases[1] = SKSpriteNode(imageNamed: "square_stride_orange")
        rightBases[2] = SKSpriteNode(imageNamed: "square_stride_light")
        rightBases[3] = SKSpriteNode(imageNamed: "square_stride_white")
        
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
        background.name = "background"
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.size = self.frame.size
        
        buildParts(side: .right)
        buildBases(side: .right)
        
//        // Position the 4 bases
//        for (index, base) in bases {
//            addChild(base)
//            base.anchorPoint = CGPoint(x: 0, y: 0.5)
//            base.zPosition = 1
//            base.name = "tone\(index+1)"
//            let overallHeight = base.frame.size.height * CGFloat(bases.count)
//            base.position = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (base.frame.size.height * 2 * CGFloat(index)))
//        }
        
        playButton.name = "playButton"
        addChild(playButton)
        playButton.zPosition = 99
        playButton.position = CGPoint(x: self.frame.size.width / 1.58, y: self.frame.size.height / 7.7)
        playButton.scale(to: CGSize(width: playButton.size.width * CGFloat(1.5), height: playButton.size.height * CGFloat(1.5)))
        
        
        
        panRecognizer.addTarget(self, action: #selector(GameScene.drag(_:)))
        self.view!.addGestureRecognizer(panRecognizer)

        audioManager.delegate = self
        changeSide(to: .left)
        showBars()
//        decodeBases(data: ["", "tone1", "", "", "tone3", "", "", "tone4", "", "", "", ""])
        
    }
    
    func buildParts(side: side) {
        switch side {
        case .left:
            for (index, part) in parts.enumerated() {
                addChild(part)
                part.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height - part.frame.size.height * 1.5 * CGFloat(index))
            }
        case .right:
            for (index, part) in parts.enumerated() {
                addChild(part)
                part.position = CGPoint(x: self.frame.size.width / 1.6, y: self.frame.size.height - part.frame.size.height * 1.5 * CGFloat(index))
            }
        }
    }
    
    func buildBases(side: side) {
        switch side {
        case .left:
            for (index, base) in bases {
                addChild(base)
                base.anchorPoint = CGPoint(x: 0, y: 0.5)
                base.zPosition = 1
                base.name = "tone\(index+1)"
                let overallHeight = base.frame.size.height * CGFloat(bases.count)
                base.position = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (base.frame.size.height * 3 * CGFloat(index)))
            }
        case .right:
            for (index, base) in bases {
                addChild(base)
                base.anchorPoint = CGPoint(x: 0, y: 0.5)
                base.zPosition = 1
                base.name = "tone\(index+1)"
                let overallHeight = base.frame.size.height * CGFloat(rightBases.count)
                base.position = CGPoint(x: self.frame.size.width / 3.88, y: (self.frame.size.height / 2) + (overallHeight / 2) - (base.frame.size.height * 3 * CGFloat(index)))
            }
        }
    }
    
    func addToScene() {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        let newSequencerPosition = audioManager.sequencer.currentRelativePosition.beats.isNaN ? 1 : Int(audioManager.sequencer.currentRelativePosition.beats)
        

        if currentSequencerPosition != newSequencerPosition && audioManager.sequencer.isPlaying {
            currentSequencerPosition = newSequencerPosition
            audioManager.updateLoop()
            highlightBase()
            showBars()
        }
       
    }
    
    // Gets called by the UIPanGestureRecognizer.
    // Describes the behaviour while being dragged and what should happen at the end of a drag.
    @objc func drag(_ gestureRecognizer: UIPanGestureRecognizer) {
        // While dragging update base's position to current finger position.
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let translation = gestureRecognizer.translation(in: self.view)

            if scrolling {
                for part in parts.reversed() {
                    part.position = CGPoint(x: part.position.x, y: part.position.y - translation.y*2)
                    if part == parts.last! {
                        if intersects(part) {
                            let newPart = SKSpriteNode(imageNamed: "circle_orange")
                            newPart.zPosition = 3
                            newPart.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                            parts.append(newPart)
                            BasesByParts.append((newPart, nil))
                            addChild(newPart)
                            if currentSide == .left {
                                newPart.position = CGPoint(x: self.frame.size.width / 2.8, y: part.position.y - part.frame.height * 1.5)
                            } else {
                                newPart.xScale = -1
                                newPart.position = CGPoint(x: self.frame.size.width / 1.6, y: part.position.y - part.frame.height * 1.5)
                            }

                        }
                    }
                }
                for base in basesOnDna {
                    base.position = CGPoint(x: base.position.x, y: base.position.y - translation.y * 2)
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
                        var newPosition = CGPoint.zero
                        if currentSide == .left {
                            newPosition = CGPoint(x: nearest.position.x + currentBase.frame.width / 24, y: nearest.position.y)
                        }
                        else {
                            currentBase.anchorPoint = CGPoint(x: 1, y: 0.5)
                            newPosition = CGPoint(x: nearest.position.x - (currentBase.frame.width / 24), y: nearest.position.y)
                        }
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
        else if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .failed {
            if let currentPart = currentPart {
                for part in parts.reversed() {
                    if part == parts.last! {
                        if intersects(part) {
                            let newPart = SKSpriteNode(imageNamed: "circle_orange")
                            newPart.zPosition = 3
                            newPart.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                            parts.append(newPart)
                            BasesByParts.append((newPart, nil))
                            addChild(newPart)
                            newPart.position = CGPoint(x: self.frame.size.width / 2.8, y: part.position.y - part.frame.height * 1.5)
                        }
                    }
                }
                gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
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

        if currentSide == .left {
            let oldAnchorPoint = base.anchorPoint
            base.anchorPoint = CGPoint(x: 0, y: base.anchorPoint.y)
            let leftMostPoint = base.position
            base.anchorPoint = oldAnchorPoint
            if (leftMostPoint.x < parts.first!.position.x - parts.first!.frame.size.width * 2 && basesOnDna.contains(base)) {
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
        }
        else {
            let oldAnchorPoint = base.anchorPoint
            base.anchorPoint = CGPoint(x: 1, y: base.anchorPoint.y)
            let rightMostPoint = base.position
            base.anchorPoint = oldAnchorPoint
            if (rightMostPoint.x > parts.first!.position.x + parts.first!.frame.size.width * 2 && basesOnDna.contains(base)) {
                cleanOldParts(from: base)
                basesOnDna.remove(at: basesOnDna.index(of: base)!)
                let leaveScreen = SKAction.moveTo(x: self.frame.width, duration: 0.5)
                let remove = SKAction.run {
                    base.removeFromParent()
                }
                let sequence = SKAction.sequence([leaveScreen, remove])
                base.run(sequence)
                reloadSample(for: base)
                return true
            }
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
                    scrolling = true
                    return
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
                    else if name == "background" || parts.contains(node){
                        currentBase = nil
                        scrolling = true
                        return
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
                scrolling = false
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
                newBase = SKSpriteNode(imageNamed: "square_stride_pink")
            case 1:
                newBase = SKSpriteNode(imageNamed: "square_stride_orange")
            case 2:
                newBase = SKSpriteNode(imageNamed: "square_stride_light")
            case 3:
                newBase = SKSpriteNode(imageNamed: "square_stride_white")
            default:
                newBase = SKSpriteNode(imageNamed: "square_stride_pink")
            }
            bases[position] = newBase
            newBase.name = "tone\(position+1)"
            addChild(newBase)
            newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
            newBase.zPosition = 1
            let overallHeight = newBase.frame.size.height * CGFloat(bases.count)
            var finalPos: CGPoint
            if currentSide == .left {
                newBase.position = CGPoint(x: self.frame.size.width, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 3 * CGFloat(position)))
                finalPos = CGPoint(x: self.frame.size.width / 1.68, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 3 * CGFloat(position)))
            }
            else {
                newBase.position = CGPoint(x: self.frame.minX, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 3 * CGFloat(position)))
                finalPos = CGPoint(x: self.frame.size.width / 3.88, y: (self.frame.size.height / 2) + (overallHeight / 2) - (newBase.frame.size.height * 3 * CGFloat(position)))
            }

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
        
        var newSequencerPosition = audioManager.sequencer.currentRelativePosition.beats.isNaN ? 0 :  Int(audioManager.sequencer.currentRelativePosition.beats)
        
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
    
    func showBars() {
      
        let bars = audioManager.beatsAmount

        for (index, part) in parts.enumerated() {
            if index+1 > Int(bars) {
                part.alpha = 0.5
            }
            else {
                part.alpha = 1.0
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
                    newBase = SKSpriteNode(imageNamed: "square_stride_pink")
                case "tone2":
                    newBase = SKSpriteNode(imageNamed: "square_stride_orange")
                case "tone3":
                    newBase = SKSpriteNode(imageNamed: "square_stride_light")
                case "tone4":
                    newBase = SKSpriteNode(imageNamed: "square_stride_white")
                default:
                    newBase = SKSpriteNode(imageNamed: "square_stride_pink")
                }
                newBase.name = name
                addChild(newBase)
                newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
                newBase.zPosition = 1

                
                newBase.position = CGPoint(x: parts.first!.position.x  + newBase.frame.width / 24, y: parts[index].position.y)
                basesOnDna.append(newBase)
                BasesByParts[index] = (BasesByParts[index].0, newBase)
                
            }
        }
    }
    
    public func changeSide(to side: side) {

        self.removeAllChildren()
        self.addChild(background)
        self.addChild(self.playButton)
        switch side {
        case .left:
            currentSide = .left
            parts = leftParts
            bases = leftBases
            passiveBasesByParts = BasesByParts
            BasesByParts = leftBasesByParts
            buildParts(side: .left)
            buildBases(side: .left)
        case .right:
            currentSide = .right
            parts = rightParts
            bases = rightBases
            passiveBasesByParts = BasesByParts
            BasesByParts = rightBasesByParts
            buildParts(side: .right)
            buildBases(side: .right)
            showBars()
        }
    }
    
}

extension GameScene : AudioManagerDelegate {
    
    public func getBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)] {
        return BasesByParts
    }
    
    public func getPassiveBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)] {
        return passiveBasesByParts
    }
    
    public func getParts() -> [SKSpriteNode] {
        return parts
    }
}

