//
//  DeviceListVC.swift
//  MPCChat
//
//  Created by apple on 13/03/19.
//  Copyright © 2019 kayosys. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class DeviceListVC: UIViewController {
    
    struct Storyboard {
        static let kCellId = "DeviceCell"
        static let deviceListVCToChatVC = "deviceListVCToChatVC"
    }

    @IBOutlet weak var deviceTableView: UITableView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var isAdvertising = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.mpcManager.delegate = self
        appDelegate.mpcManager.browser.startBrowsingForPeers()
    }
    
    
    @IBAction func startStopAdvertising(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "", message: "Change Visibility", preferredStyle: .actionSheet)
        var actionTitle: String
        if isAdvertising == true {
            actionTitle = "Make me invisible to others"
        }
        else{
            actionTitle = "Make me visible to others"
        }
        
        let visibilityAction: UIAlertAction = UIAlertAction(title: actionTitle, style: .default) { (alertAction) -> Void in
            if self.isAdvertising == true {
                self.appDelegate.mpcManager.advertiser.stopAdvertisingPeer()
            }
            else{
                self.appDelegate.mpcManager.advertiser.startAdvertisingPeer()
            }
            
            self.isAdvertising = !self.isAdvertising
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(visibilityAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
}

extension DeviceListVC: MPCManagerDelegate {
    func foundPeer() {
        deviceTableView.reloadData()
    }
    
    func lostPeer() {
        deviceTableView.reloadData()
    }
    
    func invitationWasReceived(fromPeer: String) {
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: .alert)
        
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { (acceptAction) in
            self.appDelegate.mpcManager.invitationHandler(true, self.appDelegate.mpcManager.session)
        }
        
        let declineAction = UIAlertAction(title: "Cancel", style: .cancel) { (declineAction) -> Void in
            self.appDelegate.mpcManager.invitationHandler(false, nil)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func connectedWithPeer(peerId: MCPeerID) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: Storyboard.deviceListVCToChatVC, sender: nil)
        }
    }
    
    
}

extension DeviceListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mpcManager.foundPeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.kCellId, for: indexPath)
        
        let peer = appDelegate.mpcManager.foundPeers[indexPath.row]
        cell.textLabel?.text = peer.displayName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let mpcManager = appDelegate.mpcManager {
            let selectedPeer = mpcManager.foundPeers[indexPath.row]
            appDelegate.mpcManager.browser.invitePeer(selectedPeer, to: mpcManager.session, withContext: nil, timeout: 20)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
