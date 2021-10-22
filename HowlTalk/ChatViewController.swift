//
//  ChatViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/21.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet var tableview: UITableView!
    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var sendButton: UIButton!
    
    var uid: String?
    var chatRoomUid: String?
    
    public var destinationUid: String? // 나중에 내가 채팅할 대상의 uid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        
        checkChatRoom()
    }
    
    @objc func createRoom() {
        let createRoomInfo = [
            "users": [
                uid!: true,
                destinationUid!: true
            ]
        ]
        
        if chatRoomUid == nil {
            self.sendButton.isEnabled = false
            // 방 생성 코드
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo) { error, DatabaseReference in
                if error == nil {
                    self.checkChatRoom()
                }
            }
        } else {
            let value = [
                "uid": uid!,
                "message": textfield_message.text!
            ]
            
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value)
        }
    }
    
    func checkChatRoom() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/" + uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value) { DataSnapshot in
            
            for item in DataSnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomDic = item.value as? [String: AnyObject] {
                    
                    let chatModel = ChatModel(JSON: chatRoomDic)
                    
                    if chatModel?.users[self.destinationUid!] == true {
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
