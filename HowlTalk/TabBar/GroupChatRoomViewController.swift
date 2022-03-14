//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/11/11.
//

import UIKit
import Firebase
import Alamofire
import ObjectMapper

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
    
    var peopleCount: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: .value) { datasnapshot in
            self.users = datasnapshot.value as? [String: AnyObject]
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
            Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("users").observeSingleEvent(of: .value) { (datasnapshot) in
                let dic = datasnapshot.value as! [String: Any]
                
                for item in dic.keys {
                    if item == self.uid {
                        continue
                    }
                    
                    let user = self.users![item]
//                    self.sendGcm(pushToken: user!["pushToken"] as? String)
                    self.sendGcm(pushToken: user as? String)
                }
                self.textfield_message.text = ""
            }
        }
    }
    
    func sendGcm(pushToken: String?) {
        let url = "https://fcm.googleapis.com/fcm/send"
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=AAAAIeZJXcU:APA91bGk6ArER5pbgF1NTn33lDshYWiPV0gMTfxhE7HemFzy_AOdkm8_WU7QFpRCvGimQys6XFCktDJVscJYj-D-U9VXGJn4zSIkslV5oon2_hQ54Q5aTwwR0owx6nLiEt84_65qy1cU"
        ]
        
        let userName = Auth.auth().currentUser?.displayName
        
        let notificationModel = NotificationModel()
        notificationModel.to = pushToken!
        notificationModel.notification.title = userName
        notificationModel.notification.body = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.body = textfield_message.text
        
        let params = notificationModel.toJSON()
        
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { response in
            print(response.result)
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
            
            setReadCount(label: cell.label_read_counter, position: indexPath.row)

            return cell
        } else {
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            
//            cell.label_name.text = destinationUser!["userName"] as! String
            cell.label_name.text = destinationUser!["userName"]?.stringValue
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
//            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let imageUrl = destinationUser!["profileImageUrl"]?.stringValue
            let url = URL(string: (imageUrl!))
            
            cell.imageview_profile.layer.cornerRadius = cell.imageview_profile.frame.width/2
            cell.imageview_profile.clipsToBounds = true
            cell.imageview_profile.kf.setImage(with: url)
            
            if let time = self.comments[indexPath.row].timestamp {
                cell.label_timestamp.text = time.toDayTime
            }
            
            setReadCount(label: cell.label_read_counter, position: indexPath.row)

            return cell
        }
    }

    func setReadCount(label: UILabel?, position: Int?) {
        let readCount = self.comments[position!].readUsers.count
        
        if self.peopleCount == nil {
            Database.database().reference().child("chatrooms").child(destinationRoom!).child("users").observeSingleEvent(of: .value, with: { datasnapshot in
                let dic = datasnapshot.value as! [String: Any]
                self.peopleCount = dic.count
                
                let noReadCount = self.peopleCount! - readCount
                
                if noReadCount > 0 {
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                } else {
                    label?.isHidden = true
                }
            })
        } else {
            let noReadCount = self.peopleCount! - readCount
            
            if noReadCount > 0 {
                label?.isHidden = false
                label?.text = String(noReadCount)
            } else {
                label?.isHidden = true
            }
        }
    }

    func getMessageList() {
        print("버그 위치")
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
                    readUserDic[key] = comment_modify?.toJSON() as NSDictionary?
                    
                    self.comments.append(comment!)
                    print("버그 위치1")
                }
            }
            print("버그 위치2")
            let nsDic = readUserDic as NSDictionary
            
            if self.comments.last?.readUsers.keys == nil {
                return
            }
            print("버그 위치5")
            if !(self.comments.last?.readUsers.keys.contains(self.uid!))! {
                print("버그 위치7")
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any]) { err, ref in
                    self.tableview.reloadData()
                    
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                    }
                }
            } else {
                // 여기다
                print("버그 위치8")
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
                }
            }
            print("버그 위치6")
            self.tableview.reloadData()
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count
                                                         - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
            print("버그 위치4")
        }
        print("버그 위치3")
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
