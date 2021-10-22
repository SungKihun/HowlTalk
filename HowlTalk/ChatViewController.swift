//
//  ChatViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/21.
//

import UIKit
import Firebase
import ObjectMapper

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableview: UITableView!
    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var sendButton: UIButton!
    
    var uid: String?
    var chatRoomUid: String?
    
    var comments: [ChatModel.Comment] = []
    var userModel: UserModel?
    
    public var destinationUid: String? // 나중에 내가 채팅할 대상의 uid
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.comments[indexPath.row].uid == uid {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            
            cell.label_name.text = userModel?.userName
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
            let url = URL(string: (self.userModel?.profileImageUrl)!)
            
            URLSession.shared.dataTask(with: url!) { data, response, err in
                DispatchQueue.main.async {
                    cell.imageview_profile.image = UIImage(data: data!)
                    cell.imageview_profile.layer.cornerRadius = cell.imageview_profile.frame.width/2
                    cell.imageview_profile.clipsToBounds = true
                }
            }.resume()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

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
                        
                        self.getDestinationInfo()
                    }
                }
            }
        }
    }
    
    func getDestinationInfo() {
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value) { datasnapshot in
            self.userModel = UserModel()
            self.userModel?.setValuesForKeys(datasnapshot.value as! [String: Any])
            self.getMessageList()
        }
    }
    
    func getMessageList() {
        Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments").observe(DataEventType.value) { datasnapshot in
            self.comments.removeAll()
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let comment = ChatModel.Comment(JSON: item.value as! [String: AnyObject])
                self.comments.append(comment!)
            }
            self.tableview.reloadData()
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

class MyMessageCell: UITableViewCell {
    
    @IBOutlet var label_message: UILabel!
}

class DestinationMessageCell: UITableViewCell {
    
    @IBOutlet var label_message: UILabel!
    @IBOutlet var imageview_profile: UIImageView!
    @IBOutlet var label_name: UILabel!
}
