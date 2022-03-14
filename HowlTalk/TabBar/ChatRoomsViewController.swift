//
//  ChatRoomsViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/24.
//

import UIKit
import Firebase
import Kingfisher

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableview: UITableView!

    var uid: String!
    var chatrooms: [ChatModel]! = []
    var keys: [String] = []
    var destinationUsers: [String] = []

    override func viewDidLoad() {
        print(#function)
        super.viewDidLoad()
        
        self.uid = Auth.auth().currentUser?.uid
        self.getChatroomsList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(#function)
        self.getChatroomsList()
    }
    
    func getChatroomsList() {
        // 기존에 있던 채팅방 지우고
        self.chatrooms.removeAll()
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/" + uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value) { datasnapshot in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                if let chatroomdic = item.value as? [String: AnyObject] {
                    let chatModel = ChatModel(JSON: chatroomdic)
                    self.keys.append(item.key)
                    self.chatrooms.append(chatModel!)
                }
            }
            
            self.tableview.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        var destinationUid: String?
        
        for item in chatrooms[indexPath.row].users {
            if item.key != self.uid {
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
            }
        }
        
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: {
            datasnapshot in
            
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String: AnyObject])
            
            cell.label_title.text = userModel.userName
            let url = URL(string: userModel.profileImageUrl!)
            
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width / 2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            if self.chatrooms[indexPath.row].comments.keys.count == 0 {
                return
            }
            
            let lastMessagekey = self.chatrooms[indexPath.row].comments.keys.sorted { $0 > $1 }
            cell.label_lastmessage.text = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.message
            
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.timestamp
            cell.label_timestamp.text = unixTime?.toDayTime
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        print(#function)
        print("destinationUsers: \(destinationUsers)")
        print("self.destinationUsers[indexPath.row]: \(self.destinationUsers[indexPath.row])")
//        if (self.destinationUsers[indexPath.row].count > 2) {
//            print("그룹 채팅방 선택")
//            _ = self.destinationUsers[indexPath.row]
////            let destinationUid = self.destinationUsers[indexPath.row]
//
//            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
//            view.destinationRoom = self.keys[indexPath.row]
//
//            self.navigationController?.pushViewController(view, animated: true)
//        } else {
        print("단일 채팅방 선택")
        let destinationUid = self.destinationUsers[indexPath.row]
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        view.destinationUid = destinationUid
        
        self.navigationController?.pushViewController(view, animated: true)
//        }
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableview.deselectRow(at: indexPath, animated: true)
//
//        if self.destinationUsers[indexPath.row].count > 2 {
//            let destinationUid = self.destinationUsers[indexPath.row]
//
//            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
//            view.destinationRoom = self.keys[indexPath.row]
//
//            self.navigationController?.pushViewController(view, animated: true)
//        } else {
//            let destinationUid = self.destinationUsers[indexPath.row]
//
//            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
//
//            self.navigationController?.pushViewController(view, animated: true)
//
//        }
//
//        let destinationUid = self.destinationUsers[indexPath.row]
//
//        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
//        view.destinationUid = destinationUid
//
//        self.navigationController?.pushViewController(view, animated: true)
//    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

class CustomCell: UITableViewCell {
    
    @IBOutlet var label_timestamp: UILabel!
    @IBOutlet var label_lastmessage: UILabel!
    @IBOutlet var label_title: UILabel!
    @IBOutlet var imageview: UIImageView!
}
