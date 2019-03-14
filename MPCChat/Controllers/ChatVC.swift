//
//  ChatVC.swift
//  MPCChat
//
//  Created by apple on 13/03/19.
//  Copyright © 2019 kayosys. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatVC: UIViewController {
    
    struct Storyboard {
        static let kCellId = "ChatCell"
    }

    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var chatTextField: UITextField!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var messageArray: [Dictionary<String, String>] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chatTableView.estimatedRowHeight = 60.0
        chatTableView.rowHeight = UITableView.automaticDimension
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMPCReceivedDataWithNotification), name: NSNotification.Name(rawValue: "receivedMPCDataNotification"), object: nil)
    }
    
    @objc func handleMPCReceivedDataWithNotification(notification: NSNotification) {
        // Get the dictionary containing the data and the source peer from the notification.
        if let receivedDataDictionary = notification.object as? Dictionary<String, Any> {
         
            // "Extract" the data and the source peer from the received dictionary.
            if let data = receivedDataDictionary["data"] as? Data, let fromPeer = receivedDataDictionary["fromPeer"] as? MCPeerID {
                
                do {
                    // Convert the data (Data) into a Dictionary object.
                    if let dataDict = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Dictionary<String, String> {
                        
                        // Check if there's an entry with the "message" key.
                        if let message = dataDict["message"] {
                            // Make sure that the message is other than "_end_chat_".
                            
                            if message != "_end_chat_"{
                                // Create a new dictionary and set the sender and the received message to it.
                                let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
                                
                                // Add this dictionary to the messagesArray array.
                                messageArray.append(messageDictionary)
                                
                                // Reload the tableview data and scroll to the bottom using the main thread.
                                DispatchQueue.main.async {
                                    self.updateTableView()
                                }
                            }
                            else{
                                // In this case an "_end_chat_" message was received.
                                // Show an alert view to the user.
                                let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: .alert)
                                
                                let doneAction = UIAlertAction(title: "Okay", style: .default) { (alertAction) -> Void in
                                    
                                    self.navigationController?.popViewController(animated: true)
                                    self.appDelegate.mpcManager.session.disconnect()
                                }
                                
                                alert.addAction(doneAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
                catch {
                    print("Fatal Error : \(error.localizedDescription)")
                }
            }
            
        }
    }

    @IBAction func endChatPressed(_ sender: UIBarButtonItem) {
        let messageDictionary: [String: String] = ["message": "_end_chat_"]
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mpcManager.session.connectedPeers[0]){
            self.navigationController?.popViewController(animated: true)
            //self.appDelegate.mpcManager.session.disconnect()
        }
    }
    
}

extension ChatVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.kCellId, for: indexPath)
        
        let currentMessage = messageArray[indexPath.row]
        
        if let sender = currentMessage["sender"] {
            var senderLabelText: String
            var senderColor: UIColor
            
            if sender == "self"{
                senderLabelText = "I said:"
                senderColor = UIColor.purple
            }
            else{
                senderLabelText = sender + " said:"
                senderColor = UIColor.orange
            }
            
            cell.detailTextLabel?.text = senderLabelText
            cell.detailTextLabel?.textColor = senderColor
        }
        
        if let message = currentMessage["message"] {
            cell.textLabel?.text = message
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension ChatVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let messageDict = ["message": textField.text!]
        
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDict, toPeer: appDelegate.mpcManager.session.connectedPeers[0]) {
            let dict = ["sender": "self", "message": textField.text!]
            messageArray.append(dict)
            self.updateTableView()
        }
        else {
            print("Could not send data")
        }
        
        textField.text = ""
        return true
    }
    
    func updateTableView() {
        chatTableView.reloadData()
        
        if chatTableView.contentSize.height > chatTableView.frame.size.height {
            chatTableView.scrollToRow(at: IndexPath(row: messageArray.count - 1, section: 0), at: .bottom, animated: true)
        }
        
    }
}
