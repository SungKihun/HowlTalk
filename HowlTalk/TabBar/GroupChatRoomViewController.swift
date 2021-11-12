//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/11/11.
//

import UIKit
import Firebase

class GroupChatRoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var button_send: UIButton!
    @IBOutlet var tableview: UITableView!
    
    var destinationRoom: String?
    var uid: String?
    
    var databaseRef: DatabaseReference?
    var observe: UInt?
    
    var comments: [ChatModel.Comment] = []
    var users: [String: AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: .value) { datasnapshot in
            self.users = datasnapshot.value as! [String: AnyObject]
        }
        
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        getMessageList()
    }
    
    @objc func sendMessage() {
        let value: Dictionary<String, Any> = [
            "uid": uid!,
            "message": textfield_message.text!,
            "timestamp": ServerValue.timestamp()
        ]
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value) { err, ref in
            self.textfield_message.text = ""
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.comments[indexPath.row].uid == uid {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp {
                cell.label_timestamp.text = time.toDayTime
            }
            
//            setReadCount(label: cell.label_read_counter, position: indexPath.row)

            return cell
        } else {
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            
            cell.label_name.text = destinationUser!["userName"] as! String
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string: (imageUrl))
            
            cell.imageview_profile.layer.cornerRadius = cell.imageview_profile.frame.width/2
            cell.imageview_profile.clipsToBounds = true
            cell.imageview_profile.kf.setImage(with: url)
            
            if let time = self.comments[indexPath.row].timestamp {
                cell.label_timestamp.text = time.toDayTime
            }
            
//            setReadCount(label: cell.label_read_counter, position: indexPath.row)

            return cell
        }
    }

    func getMessageList() {
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
        observe = databaseRef?.observe(DataEventType.value) { datasnapshot in
            self.comments.removeAll()
            
            var readUserDic: Dictionary<String, AnyObject> = [:]
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let key = item.key as String
                
                if let messagedic = item.value as? [String: AnyObject] {
                    let comment = ChatModel.Comment(JSON: messagedic)
                    let comment_modify = ChatModel.Comment(JSON: messagedic)
                    comment_modify?.readUsers[self.uid!] = true
                    readUserDic[key] = comment_modify?.toJSON() as! NSDictionary
                    
                    self.comments.append(comment!)
                }
            }
            
            let nsDic = readUserDic as NSDictionary
            
            if self.comments.last?.readUsers.keys == nil {
                return
            }
            
            if !(self.comments.last?.readUsers.keys.contains(self.uid!))! {
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any]) { err, ref in
                    self.tableview.reloadData()
                    
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                    }
                }
            } else {
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                }
            }
            
            self.tableview.reloadData()
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count
                                                         - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
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
