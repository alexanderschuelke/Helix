//
//  GameViewController.swift
//  HelixProto
//
//  Created by Alexander Schülke on 10.02.18.
//  Copyright © 2018 Alexander Schülke. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import MultipeerConnectivity

class GameViewController: UIViewController, UINavigationControllerDelegate, MCBrowserViewControllerDelegate, MCSessionDelegate, GameDelegate {
    
    
    enum States {
        case requesting
        case sending
        
    }
    
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tempoStepper: UIStepper!
    
    private var requestState : States = .sending
    
    @IBAction func indexChanged(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            
//            if scene!.currentSide == .left {
//                scene!.changeSide(to: .left)
//            }
            
            scene!.checkForLeftovers()
            
            if scene!.currentSide == .left {
                scene!.changeSide(to: .right)
                scene!.changeSide(to: .left)
            }
            //            scene!.dnaMode = false
            if scene!.currentSide != .left {
                scene!.changeSide(to: .left)
            }
            
            
        case 1:
            self.hideNavigator()
            if scene!.audioManager.sequencer.isPlaying {
//                scene!.playButton.playPressedAnimation(true)
            } else {
                scene!.playButton.playPressedAnimation(false)
            }

            scene!.playButton.name = "stopButton"
            scene!.audioManager.play()
            scene!.dnaMode = true
            scene!.twist()
            scene!.resizeBases()
        case 2:
            

            
            scene!.checkForLeftovers()
            
            if scene!.currentSide == .right {
                scene!.changeSide(to: .left)
                scene!.changeSide(to: .right)
            }
            //            scene!.dnaMode = false
            if scene!.currentSide != .right {
                scene!.changeSide(to: .right)
                
            }
            
        default:
            return
        }
    }
    
    @IBAction func connectivityButton(_ sender: Any) {
        showConnectionPrompt()
    }
    
    func hideNavigator() {
        self.navigationController!.navigationBar.isHidden = true
    }
    func unhideNavigator() {
        self.navigationController!.navigationBar.isHidden = false
    }
    
    @IBAction func sendButton(_ sender: Any) {
        self.requestState = .requesting
        var requestType = ""
        let alert = UIAlertController(title: "DNA Replication", message: "What do you want to send?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Melody", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in requestType = "melody"; self.sendSequence(requestType: "melody"); self.scene!.requestType = requestType}))
        alert.addAction(UIAlertAction(title: "Rhythm", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in requestType = "rhythm"; self.sendSequence(requestType: "rhythm"); self.scene!.requestType = requestType}))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func changeTempo(_ sender: Any) {
        scene?.audioManager.tempo = tempoStepper.value
        scene?.audioManager.sequencer.setTempo(scene!.audioManager.tempo)
        tempoLabel.text = String(describing: scene!.audioManager.tempo / 4)
    }
    
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var scene: GameScene?
    
    func sendSequence(requestType: String) {
        if mcSession.connectedPeers.count > 0 {
            do {
                
                let newData = NSKeyedArchiver.archivedData(withRootObject: scene?.encodeBases(for: requestType))
                try mcSession.send(newData, toPeers: mcSession.connectedPeers, with: .reliable)
                
            } catch let error as NSError {
                let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
    }
    
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = GameScene(size:CGSize(width: 2048, height: 1536))
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true
        if let scene = scene {
            scene.scaleMode = .aspectFill
            skView.presentScene(scene)
            scene.gameSceneDelegate = self
            tempoLabel.text = String(scene.audioManager.tempo / 4)
            tempoStepper.value = scene.audioManager.tempo
        }
        
        tempoStepper.autorepeat = true
        tempoStepper.stepValue = 5
        tempoStepper.maximumValue = 400
        tempoStepper.minimumValue = 5
        
        //This is the PeerID we need for the session
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        //We are creating a session
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        //We are declaring a delegate
        mcSession.delegate = self
        
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    // The MCAdvertiserAssistant is a convenience class that handles advertising, presents incoming invitations to the user, and handles users’ responses. Use this class to provide a user interface for handling invitations when your app does not require programmatic control over the invitation process.
    func startHosting(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "Helix", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    // The MCBrowserViewController class presents nearby devices to the user and enables the user to invite nearby devices to a session.
    func joinSession(action: UIAlertAction) {
        
        let mcBrowser = MCBrowserViewController(serviceType: "Helix", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func triggerSendData() {
        sendSequence(requestType: "")
    }
    
    func swipeLeft() {
        segmentedControl.selectedSegmentIndex = 0
    }
    
    func swipeRight() {
        segmentedControl.selectedSegmentIndex = 2
    }
    
    
    // IGNORE
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        let array = NSKeyedUnarchiver.unarchiveObject(with: data) as! Array<String>
        scene?.decodeBases(data: array)
        
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    
    
}

