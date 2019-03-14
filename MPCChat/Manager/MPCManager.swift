//
//  MPCManager.swift
//  MPCChat
//
//  Created by apple on 13/03/19.
//  Copyright © 2019 kayosys. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MPCManagerDelegate {
    func foundPeer()
    func lostPeer()
    func invitationWasReceived(fromPeer: String)
    func connectedWithPeer(peerId: MCPeerID)
}


class MPCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession?) -> ())!
    
    var delegate: MPCManagerDelegate?
    let serviceType = "chatService"
    
    
    
    
    override init() {
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
    }
    
    
    // MARK:- MCNearbyServiceBrowserDelegate METHODS
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        foundPeers.append(peerID)
        delegate?.foundPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        for (index, peer) in foundPeers.enumerated() {
            if peer == peerID {
                foundPeers.remove(at: index)
                break
            }
        }
        
        delegate?.lostPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error.localizedDescription)
    }
    
    // MARK:- MCNearbyServiceAdvertiserDelegate METHODS
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        self.invitationHandler = invitationHandler
        delegate?.invitationWasReceived(fromPeer: peerID.displayName)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print(error.localizedDescription)
    }
    
    // MARK:- MCSessionDelegate METHODS
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state{
        case MCSessionState.connected:
            print("Connected to session: \(session)")
            delegate?.connectedWithPeer(peerId: peerID)
            
        case MCSessionState.connecting:
            print("Connecting to session: \(session)")
            
        case MCSessionState.notConnected:
            print("Not Connecting to session: \(session)")
            
        default:
            print("Did not connect to session: \(session)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let dictionary: [String: Any] = ["data": data as Any, "fromPeer": peerID]
        NotificationCenter.default.post(name: NSNotification.Name("receivedMPCDataNotification"), object: dictionary)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        //
    }
    
    func sendData(dictionaryWithData dictionary: Dictionary<String,String>, toPeer targetPeer: MCPeerID) -> Bool {
        
        do {
            let dataToSend = try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: false)
            let peersArray = [targetPeer]
            try session.send(dataToSend, toPeers: peersArray, with: .reliable)
            return true
        }
        catch {
            print("Fatal Error : \(error.localizedDescription)")
            return false
        }
    }
}
