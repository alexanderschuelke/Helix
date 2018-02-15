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
    @IBAction func connectivityButton(_ sender: Any) {
        showConnectionPrompt()
    }
    
    @IBAction func sendButton(_ sender: Any) {
        sendSequence()
    }
   
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var scene: GameScene?
    
    func sendSequence() {
        if mcSession.connectedPeers.count > 0 {
            let newData = NSKeyedArchiver.archivedData(withRootObject: scene?.encodeBases())
            do {
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
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        if let scene = scene {
            scene.scaleMode = .aspectFill
            skView.presentScene(scene)
            scene.gameSceneDelegate = self
        }
        
        
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
        sendSequence()
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
