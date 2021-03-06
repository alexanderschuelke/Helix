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
    
    //test
    
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
    private var dancingRight: [(Int, SKSpriteNode?)] = []
    private var dancingLeft: [(Int, SKSpriteNode?)] = []
    public let audioManager = AudioManager()
    
    // For dragging bases
    private let panRecognizer = UIPanGestureRecognizer()
    
    // Currently moved base
    private var currentBase: SKSpriteNode?
    private var currentPart: SKSpriteNode?
    private var scrolling: Bool = false
    private var originalBasePosition: CGPoint?
    
    private var selectionFrame: SelectionFrame?
    public var playButton: SKSpriteNode = SKSpriteNode(imageNamed: "playbutton_new")
    private var currentSequencerPosition = -1
    public var currentSide: side = side.left
    private var opener = true
    private var blockScrolling = false
    private var maxTopPosition: CGFloat = 0
    private var clearLeftSide = false
    private var basesToClearLeft: [Int] = []
    private var clearRightSide = false
    private var basesToClearRight: [Int] = []
    private var deleteLater: [Int] = []
    private var basesByIDs: [(String, (SKSpriteNode, Double))] = []
    private var timing = 0.0
    public var dnaMode = false
    public var requestType: String = "melody"
    public var setFree = true
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
        playButton.position = CGPoint(x: self.frame.width / 2, y: self.frame.size.height / 7.7)
        playButton.scale(to: CGSize(width: playButton.size.width * CGFloat(1.5), height: playButton.size.height * CGFloat(1.5)))
        
        
        
        panRecognizer.addTarget(self, action: #selector(GameScene.drag(_:)))
        self.view!.addGestureRecognizer(panRecognizer)
        
        audioManager.delegate = self
        changeSide(to: .left)
        showBars()
        opener = false
        //        decodeBases(data: ["", "tone1", "", "", "tone3", "", "", "tone4", "", "", "", ""])
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipe(_:)))
        swipeLeft.direction = .left
        self.view!.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipe(_:)))
        swipeRight.direction = .right
        self.view!.addGestureRecognizer(swipeRight)
    }
    
    func buildParts(side: side) {
        switch side {
        case .left:
            for (index, part) in parts.enumerated() {
                if index == 0 {
                    part.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height - part.frame.size.height * 3)
                    maxTopPosition = part.position.y
                } else {
                    
                    part.position = CGPoint(x: self.frame.size.width / 2.8, y: parts[index-1].position.y - part.frame.size.height * 1.5)
                }
                addChild(part)
            }
        case .right:
            for (index, part) in parts.enumerated() {
                if index == 0 {
                    part.position = CGPoint(x: self.frame.size.width / 1.6, y: self.frame.size.height - part.frame.size.height * 3)
                } else {
                    part.position = CGPoint(x: self.frame.size.width / 1.6, y: parts[index-1].position.y - part.frame.size.height * 1.5)
                }
                addChild(part)
            }
        }
    }
    
    func printBasesByParts() {
        var result = "----normal----"
        for (index, value) in BasesByParts.enumerated() {
            if let base = value.1 {
                result += "[\(index)]: \(base.name!)"
            }
        }
        print(result)
        
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
        print(dnaMode)
        // Called before each frame is rendered
        //                printBasesByParts()
        let newSequencerPosition = audioManager.sequencer.currentRelativePosition.beats.isNaN ? 1 : Int(audioManager.sequencer.currentRelativePosition.beats)
        
        
        
        if currentSequencerPosition != newSequencerPosition && audioManager.sequencer.isPlaying {
            currentSequencerPosition = newSequencerPosition
            audioManager.updateLoop()
            highlightBase()
            showBars()
            
        }
        
        timing += 0.01
        if audioManager.sequencer.isPlaying && dnaMode{
            if currentSide == .left {
                for (index, value) in dancingRight {
                    if index < rightParts.count {
                        if let base = value {
                            base.position.x = rightParts[index].position.x
                        }
                    }
                    
                }
                for (index, value) in BasesByParts.enumerated() {
                    if let base = value.1 {
                        base.position.x = leftParts[index].position.x - (base.frame.width / 24)
                    }
                }
            } else {
                for (index, value) in dancingLeft {
                    if index < leftParts.count {
                        if let base = value {
                            base.position.x = leftParts[index].position.x
                        }
                    }
                    
                }
                for (index, value) in BasesByParts.enumerated() {
                    if let base = value.1 {
                        base.position.x = rightParts[index].position.x - (base.frame.width / 24)
                    }
                }
            }
            
        }
        
    }
    
    public func alignParts() {
        print("start align")
        print(rightParts.count)
        print(leftParts.count)
        if currentSide == .left {
            for (index, rightPart) in rightParts.enumerated() {
                if index < leftParts.count {
                    rightParts[index].position.y = leftParts[index].position.y
                }
            }
        }
        for (index, value) in dancingRight {
            if index < rightParts.count {
                if let base = value {
                    print("treffer")
                    base.position.y = rightParts[index].position.y
                }
                else {
                    print("-")
                }
            }
        }
    }
    
    @objc func swipe(_ gesture: UISwipeGestureRecognizer) -> Void {
        if gesture.direction == .left {
            gameSceneDelegate?.swipeLeft()
        } else if gesture.direction == .right {
            gameSceneDelegate?.swipeRight()
        }
    }
    
    // Gets called by the UIPanGestureRecognizer.
    // Describes the behaviour while being dragged and what should happen at the end of a drag.
    @objc func drag(_ gestureRecognizer: UIPanGestureRecognizer) {
        // While dragging update base's position to current finger position.
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let translation = gestureRecognizer.translation(in: self.view)
            
            if scrolling && !dnaMode{
                if !blockScrolling {
                    if parts.first!.position.y < maxTopPosition && translation.y > 0{
                        return
                    }
                    for part in parts.reversed() {
                        part.position = CGPoint(x: part.position.x, y: part.position.y - translation.y*2)
                        if part == parts.last! {
                            if intersects(part) {
                                let newPart = SKSpriteNode(imageNamed: "circle_orange")
                                newPart.zPosition = 3
                                newPart.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                                newPart.alpha = 0.5
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
                        let blockScroll = SKAction.run {
                            self.blockScrolling = true
                        }
                        let enableScroll = SKAction.run {
                            self.blockScrolling = false
                        }
                        let snap = SKAction.move(to: newPosition, duration: 0.1)
                        let sequence = SKAction.sequence([blockScroll, snap, enableScroll])
                        currentBase.run(sequence)
                        
                        if !basesOnDna.contains(currentBase) {
                            basesOnDna.append(currentBase)
                        }
                        for (index, tuple) in BasesByParts.enumerated() {
                            if tuple.0 == nearest {
                                cleanOldParts(from: currentBase)
                                BasesByParts[index] = (nearest, currentBase)
                                showBars()
                                //                                gameSceneDelegate?.triggerSendData()
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
                    let blockScroll = SKAction.run {
                        self.blockScrolling = true
                    }
                    let enableScroll = SKAction.run {
                        self.blockScrolling = false
                    }
                    let snapBack = SKAction.move(to: originalBasePosition, duration: 0.3)
                    let sequence = SKAction.sequence([blockScroll, snapBack, enableScroll])
                    currentBase.run(sequence)
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
                showBars()
                //                gameSceneDelegate?.triggerSendData()
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
                showBars()
                //                gameSceneDelegate?.triggerSendData()
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
                        if gameSceneDelegate?.getCurrentIndex() == 1 {
                            if audioManager.sequencer.isPlaying {
                                //                scene!.playButton.playPressedAnimation(true)
                            } else {
                                node.playPressedAnimation(false)
                            }
                            
                            node.name = "stopButton"
                            audioManager.play()
                            dnaMode = true
                            twist(true)
                            resizeBases()
                        }
                        node.playPressedAnimation(false)
                        node.name = "stopButton"
                        audioManager.play()
                    }
                    else if name == "stopButton"{
                        
                        node.playPressedAnimation(true)
                        node.name = "playButton"
                        if dnaMode {
                            
                            stopAnimation()
                            
                        }
                        gameSceneDelegate?.unhideNavigator()
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
        
        audioManager.beatsAmount = audioManager.checkBeatAmount(basesByParts: BasesByParts, parts: parts)
        
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
    
    func encodeBases(for requestType: String) -> [String] {
        if requestType == "melody" {
            if currentSide == .left {
                var result:[String] = []
                result.append("melody")
                for (index, value) in BasesByParts.enumerated() {
                    if let base = value.1 {
                        result.append(base.name!)
                    }
                    else {
                        result.append("")
                    }
                }
                return result
            } else {
                var result: [String] = []
                result.append("melody")
                for (index, value) in leftBasesByParts.enumerated() {
                    if let base = value.1 {
                        result.append(base.name!)
                    }
                    else {
                        result.append("")
                    }
                }
                return result
            }
        } else {
            if currentSide == .right {
                var result:[String] = []
                result.append("rhythm")
                for (index, value) in BasesByParts.enumerated() {
                    if let base = value.1 {
                        result.append(base.name!)
                    }
                    else {
                        result.append("")
                    }
                }
                return result
            } else {
                var result: [String] = []
                result.append("rhythm")
                for (index, value) in rightBasesByParts.enumerated() {
                    if let base = value.1 {
                        result.append(base.name!)
                    }
                    else {
                        result.append("")
                    }
                }
                return result
            }
        }
        //        else {
        //            if currentSide == .left {
        //                return rightBasesByParts
        //            } else {
        //                return BasesByParts
        //            }
        //
        return [""]
    }
    
    func decodeBases(data: [String]) {
        
        var comingFrom = data[0]
        if comingFrom == "melody" {
            if currentSide == .left {
                for (index, value) in BasesByParts.enumerated() {
                    
                    if let base = value.1 {
                        BasesByParts[index] = (BasesByParts[index].0, nil)
                        base.removeFromParent()
                    }
                }
                leftBasesByParts.removeAll()
                for (index, name) in data.enumerated() {
                    if index == 0 {
                        continue
                    }
                    if name == "" {
                        continue
                    }
                    
                    
                    let currentName = name
                    var spriteName = ""
                    switch currentName {
                    case "tone1":
                        spriteName = "square_stride_pink"
                    case "tone2":
                        spriteName = "square_stride_orange"
                    case "tone3":
                        spriteName = "square_stride_light"
                    case "tone4":
                        spriteName = "square_stride_white"
                    default:
                        spriteName = "square_stride_pink"
                    }
                    let newBase = SKSpriteNode(imageNamed: spriteName)
                    newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
                    newBase.zPosition = 1
                    newBase.name = name
                    newBase.position = CGPoint(x: leftParts[index].position.x - newBase.frame.width / 24, y: leftParts[index-1].position.y)
                    addChild(newBase)
                    basesOnDna.append(newBase)
                    if index < BasesByParts.count {
                        BasesByParts[index-1] = (BasesByParts[index-1].0, newBase)
                    }
                }
                showBars()
            }
            else if currentSide == .right {
                for (index, value) in leftBasesByParts.enumerated() {
                    if let base = value.1 {
                        BasesByParts[index] = (BasesByParts[index].0, nil)
                    }
                }
                
                for (index, name) in data.enumerated() {
                    if index == 0 {
                        continue
                    }
                    if name == "" {
                        continue
                    }
                    
                    let currentName = name
                    var spriteName = ""
                    switch currentName {
                    case "tone1":
                        spriteName = "square_stride_pink"
                    case "tone2":
                        spriteName = "square_stride_orange"
                    case "tone3":
                        spriteName = "square_stride_light"
                    case "tone4":
                        spriteName = "square_stride_white"
                    default:
                        spriteName = "square_stride_pink"
                    }
                    let newBase = SKSpriteNode(imageNamed: spriteName)
                    //                    newBase.anchorPoint = CGPoint(x: 1, y: 0.5)
                    //                    newBase.zPosition = 1
                    newBase.name = name
                    //                    newBase.position = CGPoint(x: rightParts[index].position.x + newBase.frame.width / 24, y: rightParts[index].position.y)
                    addChild(newBase)
                    //                    basesOnDna.append(newBase)
                    //                    print(BasesByParts.count)
                    if index < BasesByParts.count {
                        leftBasesByParts[index-1] = (leftBasesByParts[index-1].0, newBase)
                    }
                }
                showBars()
            }
            //            else {
            //                leftBasesByParts = data
            //            }
            //        }
            //        else {
            //            if currentSide == .left {
            //                rightBasesByParts = data
            //            } else {
            //                BasesByParts = data
            //            }
            //        }
        } else {
            if currentSide == .right {
                for (index, value) in BasesByParts.enumerated() {
                    
                    if let base = value.1 {
                        BasesByParts[index] = (BasesByParts[index].0, nil)
                        base.removeFromParent()
                    }
                }
                rightBasesByParts.removeAll()
                for (index, name) in data.enumerated() {
                    if index == 0 {
                        continue
                    }
                    if name == "" {
                        continue
                    }
                    
                    let currentName = name
                    var spriteName = ""
                    switch currentName {
                    case "tone1":
                        spriteName = "square_stride_pink"
                    case "tone2":
                        spriteName = "square_stride_orange"
                    case "tone3":
                        spriteName = "square_stride_light"
                    case "tone4":
                        spriteName = "square_stride_white"
                    default:
                        spriteName = "square_stride_pink"
                    }
                    let newBase = SKSpriteNode(imageNamed: spriteName)
                    newBase.anchorPoint = CGPoint(x: 1, y: 0.5)
                    newBase.zPosition = 1
                    newBase.name = name
                    newBase.position = CGPoint(x: rightParts[index].position.x + newBase.frame.width / 24, y: rightParts[index-1].position.y)
                    addChild(newBase)
                    basesOnDna.append(newBase)
                    
                    if index < BasesByParts.count {
                        BasesByParts[index-1] = (BasesByParts[index-1].0, newBase)
                    }
                }
                showBars()
            }
            else if currentSide == .left {
                for (index, value) in rightBasesByParts.enumerated() {
                    if let base = value.1 {
                        BasesByParts[index] = (BasesByParts[index].0, nil)
                    }
                }
                for (index, name) in data.enumerated() {
                    if index == 0 {
                        continue
                    }
                    if name == "" {
                        continue
                    }
                    
                    let currentName = name
                    var spriteName = ""
                    switch currentName {
                    case "tone1":
                        spriteName = "square_stride_pink"
                    case "tone2":
                        spriteName = "square_stride_orange"
                    case "tone3":
                        spriteName = "square_stride_light"
                    case "tone4":
                        spriteName = "square_stride_white"
                    default:
                        spriteName = "square_stride_pink"
                    }
                    let newBase = SKSpriteNode(imageNamed: spriteName)
                    newBase.anchorPoint = CGPoint(x: 1, y: 0.5)
                    //                    newBase.zPosition = 1
                    newBase.name = name
                    //                    newBase.position = CGPoint(x: rightParts[index].position.x + newBase.frame.width / 24, y: rightParts[index].position.y)
                    //                    addChild(newBase)
                    //                    basesOnDna.append(newBase)
                    //                    print(BasesByParts.count)
                    if index < rightBasesByParts.count {
                        rightBasesByParts[index-1] = (rightBasesByParts[index-1].0, newBase)
                    }
                }
                showBars()
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
            if !opener {
                rightBasesByParts = BasesByParts
            }
            
            BasesByParts = leftBasesByParts
            //            kickBases()
            buildParts(side: .left)
            buildBases(side: .left)
            restorePositions(side: .left)
            showBars()
        case .right:
            currentSide = .right
            parts = rightParts
            bases = rightBases
            leftBasesByParts = BasesByParts
            BasesByParts = rightBasesByParts
            //            kickBases()
            buildParts(side: .right)
            buildBases(side: .right)
            restorePositions(side: .right)
            showBars()
        }
        //        gameSceneDelegate?.triggerSendData()
        
    }
    
    public func kickBases() {
        print("function call")
        for (index, outerValue) in BasesByParts.enumerated() {
            print("begin loop")
            if let base = outerValue.1 {
                print("base from baseparts")
                if let name = base.name {
                    print("name of base \(name)")
                    if let divider2 = name.index(of: ".") {
                        let ownID = String(name[divider2...])
                        print(ownID)
                        var exists = false
                        var firstBase: SKSpriteNode
                        var firstTiming = 0.0
                        for (index, value) in basesByIDs.enumerated() {
                            let id = value.0
                            if id == ownID && !exists {
                                print("first found!")
                                exists = true
                                firstBase = value.1.0
                                firstTiming = value.1.1
                            } else if id == ownID && exists {
                                print("second found!")
                                let secondBase = value.1.0
                                let secondTiming = value.1.1
                                if firstTiming < secondTiming {
                                    print("first shorter")
                                    BasesByParts[index] = (BasesByParts[index].0, nil)
                                    base.removeFromParent()
                                    print("TRIUMPH")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func restorePositions(side: side) {
        for (index, tuple) in BasesByParts.enumerated() {
            if let base = tuple.1 {
                
                if deleteLater.contains(index) {
                    BasesByParts[index] = (BasesByParts[index].0, nil)
                    let remove = SKAction.moveTo(x: self.frame.width, duration: 0.2)
                    let trash = SKAction.run {
                        base.removeFromParent()
                    }
                    let sequence = SKAction.sequence([remove, trash])
                    base.run(sequence)
                }
                
                var spriteName = "square_stride_pink"
                var tonename = "tone1"
                if let name = base.name {
                    
                    
                    
                    switch name {
                    case "tone1":
                        spriteName = "square_stride_pink"
                    case "tone2":
                        spriteName = "square_stride_orange"
                    case "tone3":
                        spriteName = "square_stride_light"
                    case "tone4":
                        spriteName = "square_stride_white"
                    default:
                        spriteName = "square_stride_pink"
                    }
                    tonename = name
                }
                var newBase = SKSpriteNode(imageNamed: spriteName)
                if let p = basesOnDna.index(of: base) {
                    basesOnDna.remove(at: p)
                }
                basesOnDna.append(newBase)
                newBase.name = tonename
                addChild(newBase)
                newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
                newBase.zPosition = 1
                
                BasesByParts[index] = (tuple.0, newBase)
                if side == .left {
                    newBase.position = CGPoint(x: tuple.0.position.x + newBase.frame.width / 24, y: tuple.0.position.y)
                }
                else {
                    newBase.anchorPoint = CGPoint(x: 1, y: 0.5)
                    newBase.position = CGPoint(x: tuple.0.position.x - newBase.frame.width / 24, y: tuple.0.position.y)
                }
            }
        }
    }
    
    public func twist(_ alreadyThere: Bool) {
        if !alreadyThere {
            removeSelection(side: currentSide)
            getOtherSide(side: currentSide)
        }

        alignParts()
        if currentSide == .left {
            for part in leftParts {
                part.alpha = 1
            }
            for (index, part) in leftParts.enumerated() {
                if alreadyThere {
                    
                }
                let waitFirst = SKAction.wait(forDuration: 1.2)
                let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                let move2 = SKAction.moveBy(x: self.frame.size.width / 1.6 - part.position.x, y: 0, duration: 1)
                move2.timingMode = .easeInEaseOut
                let move3 = SKAction.moveBy(x: -(self.frame.size.width / 1.6 - part.position.x), y: 0, duration: 1)
                move3.timingMode = .easeInEaseOut
                let shrink = SKAction.scale(to: 0.5, duration: 1)
                let grow = SKAction.scale(to: 1, duration: 1)
                let sizeSequence = SKAction.sequence([shrink, grow])
                let sequence = SKAction.sequence([move2, move3])
                let group = SKAction.group([sequence, sizeSequence])
                let repeatSequence = SKAction.repeatForever(sequence)
                
                let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                
                part.run(finalSequence)
            }
            
            for (index, part) in rightParts.enumerated() {
                let waitFirst = SKAction.wait(forDuration: 1.2)
                let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                let move2 = SKAction.moveBy(x: -(self.frame.size.width / 1.6 - leftParts.first!.position.x), y: 0, duration: 1)
                move2.timingMode = .easeInEaseOut
                let move3 = SKAction.moveBy(x: (self.frame.size.width / 1.6 - leftParts.first!.position.x), y: 0, duration: 1)
                move3.timingMode = .easeInEaseOut
                let shrink = SKAction.scale(to: 0.5, duration: 1)
                let grow = SKAction.scale(to: 1, duration: 1)
                let sizeSequence = SKAction.sequence([shrink, grow])
                let sequence = SKAction.sequence([move2, move3])
                let group = SKAction.group([sequence, sizeSequence])
                let repeatSequence = SKAction.repeatForever(sequence)
                
                let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                
                part.run(finalSequence)
            }
        }
        else {
            for part in rightParts {
                part.alpha = 1
            }
            for (index, part) in leftParts.enumerated() {
                let waitFirst = SKAction.wait(forDuration: 1.2)
                let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                let move2 = SKAction.moveBy(x: (self.frame.size.width / 1.6 - part.position.x) / 2, y: 0, duration: 1)
                move2.timingMode = .easeInEaseOut
                let move3 = SKAction.moveBy(x: (-(self.frame.size.width / 1.6 - part.position.x)) / 2, y: 0, duration: 1)
                move3.timingMode = .easeInEaseOut
                let shrink = SKAction.scale(to: 0.5, duration: 1)
                let grow = SKAction.scale(to: 1, duration: 1)
                let sizeSequence = SKAction.sequence([shrink, grow])
                let sequence = SKAction.sequence([move2, move3])
                let group = SKAction.group([sequence, sizeSequence])
                let repeatSequence = SKAction.repeatForever(sequence)
                
                let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                
                part.run(finalSequence)
            }
            
            for (index, part) in rightParts.enumerated() {
                let waitFirst = SKAction.wait(forDuration: 1.2)
                let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                let move2 = SKAction.moveBy(x: (-(self.frame.size.width / 1.6 - leftParts.first!.position.x)) / 2, y: 0, duration: 1)
                move2.timingMode = .easeInEaseOut
                let move3 = SKAction.moveBy(x: ((self.frame.size.width / 1.6 - leftParts.first!.position.x)) / 2, y: 0, duration: 1)
                move3.timingMode = .easeInEaseOut
                let shrink = SKAction.scale(to: 0.5, duration: 1)
                let grow = SKAction.scale(to: 1, duration: 1)
                let sizeSequence = SKAction.sequence([shrink, grow])
                let sequence = SKAction.sequence([move2, move3])
                let group = SKAction.group([sequence, sizeSequence])
                let repeatSequence = SKAction.repeatForever(sequence)
                
                let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                
                part.run(finalSequence)
            }
        }
    }
    
    func resizeBases() {
        if currentSide == .left {
            for (index, value) in BasesByParts.enumerated() {
                if let base = value.1 {
                    let waitFirst = SKAction.wait(forDuration: 1.2)
                    let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                    let setAnchorLeft = SKAction.run {
                        base.anchorPoint = CGPoint(x: 0, y: 0.5)
                    }
                    //                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    let setAnchorRight = SKAction.run {
                        base.anchorPoint = CGPoint(x: 1, y: 0.5)
                    }
                    //                    let grow = SKAction.scaleX(to: 1, duration: 0.5)
                    //
                    //                    let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    shrink.timingMode = .linear
                    let grow = SKAction.scaleX(to: 1, duration: 0.5)
                    grow.timingMode = .linear
                    let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
                    let repeatSequence = SKAction.repeatForever(sequence)
                    let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                    base.run(finalSequence)
                }
            }
            for (index, value) in dancingRight {
                if let base = value {
                    let waitFirst = SKAction.wait(forDuration: 1.2)
                    let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                    let setAnchorLeft = SKAction.run {
                        base.anchorPoint = CGPoint(x: 0, y: 0.5)
                    }
                    //                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    let setAnchorRight = SKAction.run {
                        base.anchorPoint = CGPoint(x: 1, y: 0.5)
                    }
                    //                    let grow = SKAction.scaleX(to: 1, duration: 0.5)
                    //
                    //                    let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    shrink.timingMode = .linear
                    let grow = SKAction.scaleX(to: 1, duration: 0.5)
                    grow.timingMode = .linear
                    let sequence = SKAction.sequence([setAnchorRight, shrink, setAnchorLeft, grow, shrink, setAnchorRight, grow])
                    let repeatSequence = SKAction.repeatForever(sequence)
                    let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                    base.run(finalSequence)
                }
            }
        } else {
            for (index, value) in BasesByParts.enumerated() {
                if let base = value.1 {
                    let waitFirst = SKAction.wait(forDuration: 1.2)
                    let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                    let setAnchorLeft = SKAction.run {
                        base.anchorPoint = CGPoint(x: 1, y: 0.5)
                    }
                    //                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    let setAnchorRight = SKAction.run {
                        base.anchorPoint = CGPoint(x: 0, y: 0.5)
                    }
                    //                    let grow = SKAction.scaleX(to: 1, duration: 0.5)
                    //
                    //                    let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    shrink.timingMode = .linear
                    let grow = SKAction.scaleX(to: 1.2, duration: 0.5)
                    grow.timingMode = .linear
                    let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
                    let repeatSequence = SKAction.repeatForever(sequence)
                    let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                    base.run(finalSequence)
                }
            }
            for (index, value) in dancingLeft {
                if let base = value {
                    let waitFirst = SKAction.wait(forDuration: 1.2)
                    let wait = SKAction.wait(forDuration: Double(index) / Double(6))
                    let setAnchorLeft = SKAction.run {
                        base.anchorPoint = CGPoint(x: 1, y: 0.5)
                    }
                    //                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    let setAnchorRight = SKAction.run {
                        base.anchorPoint = CGPoint(x: 0, y: 0.5)
                    }
                    //                    let grow = SKAction.scaleX(to: 1, duration: 0.5)
                    //
                    //                    let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
                    let shrink = SKAction.scaleX(to: 0, duration: 0.5)
                    shrink.timingMode = .linear
                    let grow = SKAction.scaleX(to: 1.2, duration: 0.5)
                    grow.timingMode = .linear
                    let sequence = SKAction.sequence([setAnchorRight, shrink, setAnchorLeft, grow, shrink, setAnchorRight, grow])
                    let repeatSequence = SKAction.repeatForever(sequence)
                    let finalSequence = SKAction.sequence([waitFirst, wait, repeatSequence])
                    base.run(finalSequence)
                }
            }
        }
    }
    
    //        for (index, value) in leftBasesByParts.enumerated() {
    //            let wait = SKAction.wait(forDuration: Double(index) / Double(6))
    //            if let currentBase = value.1 {
    //                let setAnchorLeft = SKAction.run {
    //                    print("setAnchor")
    //                    currentBase.anchorPoint = CGPoint(x: 0, y: 0.5)
    //                }
    //                let shrink = SKAction.scaleX(to: 0, duration: 0.5)
    //                let setAnchorRight = SKAction.run {
    //                    print("setAnchor")
    //                    currentBase.anchorPoint = CGPoint(x: 1, y: 0.5)
    //                }
    //                let grow = SKAction.scaleX(to: 1, duration: 0.5)
    //
    //                let sequence = SKAction.sequence([setAnchorRight, shrink, setAnchorLeft, grow, shrink, setAnchorRight, grow])
    //                //                let reversed = sequence.reversed()
    //                let repeatSequence = SKAction.repeatForever(sequence)
    //                let finalSequence = SKAction.sequence([wait, repeatSequence])
    //                currentBase.run(finalSequence)
    //            }
    //        }
    //
    //        for (index, value) in rightBasesByParts.enumerated() {
    //            let wait = SKAction.wait(forDuration: Double(index) / Double(6))
    //            if let currentBase = value.1 {
    //                let setAnchorLeft = SKAction.run {
    //                    print("setAnchor")
    //                    currentBase.anchorPoint = CGPoint(x: 0, y: 0.5)
    //                }
    //                let shrink = SKAction.scaleX(to: 0, duration: 0.5)
    //                let setAnchorRight = SKAction.run {
    //                    print("setAnchor")
    //                    currentBase.anchorPoint = CGPoint(x: 1, y: 0.5)
    //                }
    //                let grow = SKAction.scaleX(to: 1, duration: 0.5)
    //
    //                let sequence = SKAction.sequence([setAnchorLeft, shrink, setAnchorRight, grow, shrink, setAnchorLeft, grow])
    //                //                let reversed = sequence.reversed()
    //                let repeatSequence = SKAction.repeatForever(sequence)
    //                let finalSequence = SKAction.sequence([wait, repeatSequence])
    //                currentBase.run(finalSequence)
    //            }
    //        }
    
    
    private func removeSelection(side: side) {
        if side == .left {
            for base in bases.values {
                let remove = SKAction.moveTo(x: self.frame.width, duration: 0.3)
                base.run(remove)
            }
        }
        else {
            for base in bases.values {
                let remove = SKAction.moveTo(x: 0, duration: 0.3)
                base.run(remove)
            }
        }
    }
    
    private func getOtherSide(side: side) {
        if side == .left {
            for (index, part) in rightParts.enumerated() {
                addChild(part)
                let wait = SKAction.wait(forDuration: 0.4)
                if index == 0 {
                    part.position = CGPoint(x: self.frame.width, y: self.frame.height - part.frame.height * 3)
                } else {
                    part.position = CGPoint(x: self.frame.width, y: rightParts[index-1].position.y - part.frame.size.height * 1.5)
                }
                
                let finalPosition = self.frame.size.width / 1.6
                let moveTo = SKAction.moveTo(x: finalPosition, duration: 0.5)
                let sequence = SKAction.sequence([wait, moveTo])
                part.run(sequence)
            }
            for (index, tuple) in rightBasesByParts.enumerated() {
                if let base = tuple.1 {
                    var spriteName = "square_stride_pink"
                    var tonename = "tone1"
                    if let name = base.name {
                        switch name {
                        case "tone1":
                            spriteName = "square_stride_pink"
                        case "tone2":
                            spriteName = "square_stride_orange"
                        case "tone3":
                            spriteName = "square_stride_light"
                        case "tone4":
                            spriteName = "square_stride_white"
                        default:
                            spriteName = "square_stride_pink"
                        }
                        tonename = name
                    }
                    var newBase = SKSpriteNode(imageNamed: spriteName)
                    basesOnDna.append(newBase)
                    newBase.name = tonename
                    addChild(newBase)
                    newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
                    newBase.zPosition = 1
                    dancingRight.append((index, newBase))
                    let wait = SKAction.wait(forDuration: 0.4)
                    newBase.anchorPoint = CGPoint(x: 1, y: 0.5)
                    newBase.position = CGPoint(x: self.frame.width, y: tuple.0.position.y)
                    let finalPosition = self.frame.size.width / 1.6 + newBase.frame.width / 24
                    let moveTo = SKAction.moveTo(x: finalPosition, duration: 0.5)
                    let sequence = SKAction.sequence([wait, moveTo])
                    newBase.run(sequence)
                    
                }
                dancingRight.append((index, nil))
            }
        }
        else {
            for (index, part) in leftParts.enumerated() {
                addChild(part)
                let wait = SKAction.wait(forDuration: 0.4)
                if index == 0 {
                    part.position = CGPoint(x: 0, y: self.frame.height - part.frame.height * 3)
                } else {
                    part.position = CGPoint(x: 0, y: leftParts[index-1].position.y - part.frame.size.height * 1.5)
                }
                let finalPosition = self.frame.size.width / 2.8
                let moveTo = SKAction.moveTo(x: finalPosition, duration: 0.5)
                let sequence = SKAction.sequence([wait, moveTo])
                part.run(sequence)
            }
            for (index, tuple) in leftBasesByParts.enumerated() {
                if let base = tuple.1 {
                    var spriteName = "square_stride_pink"
                    var tonename = "tone1"
                    if let name = base.name {
                        switch name {
                        case "tone1":
                            spriteName = "square_stride_pink"
                        case "tone2":
                            spriteName = "square_stride_orange"
                        case "tone3":
                            spriteName = "square_stride_light"
                        case "tone4":
                            spriteName = "square_stride_white"
                        default:
                            spriteName = "square_stride_pink"
                        }
                        tonename = name
                    }
                    var newBase = SKSpriteNode(imageNamed: spriteName)
                    basesOnDna.append(newBase)
                    newBase.name = tonename
                    addChild(newBase)
                    newBase.zPosition = 1
                    dancingLeft.append((index, newBase))
                    let wait = SKAction.wait(forDuration: 0.4)
                    newBase.anchorPoint = CGPoint(x: 0, y: 0.5)
                    newBase.position = CGPoint(x: 0, y: tuple.0.position.y)
                    let finalPosition = self.frame.size.width / 2.8 - newBase.frame.width / 24
                    let moveTo = SKAction.moveTo(x: finalPosition, duration: 0.5)
                    let sequence = SKAction.sequence([wait, moveTo])
                    newBase.run(sequence)
                    
                }
            }
        }
    }
    
    func stopAnimation() {
        if currentSide == .left {
            for (index, value) in BasesByParts.enumerated() {
                value.0.removeAllActions()
                let moveBack = SKAction.moveTo(x: self.frame.width / 2.8, duration: 1)
                moveBack.timingMode = .easeInEaseOut
                value.0.run(moveBack)
                if let base = value.1 {
                    base.anchorPoint = CGPoint(x: 0, y: 0.5)
                    let rescale = SKAction.scaleX(to: 1, duration: 0.5)
                    base.removeAllActions()
                    let move = SKAction.moveTo(x: self.frame.width / 2.8  - base.frame.width / 24, duration: 1)
                    let group = SKAction.group([rescale, move])
                    group.timingMode = .easeInEaseOut
                    base.run(group)
                }
            }
            
            for (index, base) in dancingRight {
                if let base = base {
                    base.anchorPoint = CGPoint(x: 1, y: 0.5)
                    let rescale = SKAction.scaleX(to: 1, duration: 0.5)
                    let moveBack = SKAction.moveTo(x: self.frame.width / 1.6 + base.frame.width / 24, duration: 1)
                    let group = SKAction.group([rescale, moveBack])
                    group.timingMode = .easeInEaseOut
                    base.removeAllActions()
                    base.run(group)
                    if let index = basesOnDna.index(of: base) {
                        basesOnDna.remove(at: index)
                    }
                    
                }
            }
            
            for part in rightParts {
                part.removeAllActions()
                let moveBack = SKAction.moveTo(x: self.frame.width / 1.6, duration: 1)
                moveBack.timingMode = .easeInEaseOut
                part.run(moveBack)
                
            }
        } else {
            for (index, value) in BasesByParts.enumerated() {
                value.0.removeAllActions()
                let moveBack = SKAction.moveTo(x: self.frame.width / 1.6, duration: 1)
                moveBack.timingMode = .easeInEaseOut
                value.0.run(moveBack)
                if let base = value.1 {
                    base.anchorPoint = CGPoint(x: 1, y: 0.5)
                    let rescale = SKAction.scaleX(to: 1, duration: 0.5)
                    base.removeAllActions()
                    let move = SKAction.moveTo(x: self.frame.width / 1.6  + base.frame.width / 24, duration: 1)
                    let group = SKAction.group([rescale, move])
                    group.timingMode = .easeInEaseOut
                    base.run(group)
                }
            }
            
            for (index, base) in dancingLeft {
                if let base = base {
                    base.anchorPoint = CGPoint(x: 0, y: 0.5)
                    let rescale = SKAction.scaleX(to: 1, duration: 0.5)
                    let moveBack = SKAction.moveTo(x: self.frame.width / 2.8 - base.frame.width / 24, duration: 1)
                    let group = SKAction.group([rescale, moveBack])
                    group.timingMode = .easeInEaseOut
                    base.removeAllActions()
                    base.run(group)
                    if let index = basesOnDna.index(of: base) {
                        basesOnDna.remove(at: index)
                    }
                    
                }
            }
            
            for part in leftParts {
                part.removeAllActions()
                let moveBack = SKAction.moveTo(x: self.frame.width / 2.8, duration: 1)
                moveBack.timingMode = .easeInEaseOut
                part.run(moveBack)
                
            }
            
        }
        
        
        
        
    }
    
    func checkForLeftovers() {
        
        if dnaMode {
            
            dnaMode = false
            
            if currentSide == .left {
                showBars()
                for (index, base) in dancingRight {
                    print("in")
                    if let cbase = base {
                        print("destroy")
                        cbase.removeFromParent()
                    }
                }
                dancingRight.removeAll()
                setFree = true
            }
            else {
                showBars()
                for (index, base) in dancingLeft {
                    if let cbase = base {
                        cbase.removeFromParent()
                    }
                }
                dancingLeft.removeAll()
                setFree = true
            }
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
    
    public func getLeftBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)] {
        return leftBasesByParts
    }
    
    public func getRightBasesByParts() -> [(SKSpriteNode, SKSpriteNode?)] {
        return rightBasesByParts
    }
    
    public func getParts() -> [SKSpriteNode] {
        return parts
    }
    
    public func getleftParts() -> [SKSpriteNode] {
        return leftParts
    }
    
    public func getRightParts() -> [SKSpriteNode] {
        return rightParts
    }
    
    public func getCurrentSide() -> GameScene.side {
        return currentSide
    }
}

