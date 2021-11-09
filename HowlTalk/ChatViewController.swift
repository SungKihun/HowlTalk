//
//  ChatViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/21.
//

import UIKit
import Firebase
import Alamofire
import Kingfisher

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var bottomContraint: NSLayoutConstraint!
    @IBOutlet var tableview: UITableView!
    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var sendButton: UIButton!
    
    var uid: String?
    var chatRoomUid: String?
    
    var comments: [ChatModel.Comment] = []
    var destinationUserModel: UserModel?
    
    public var destinationUid: String? // 나중에 내가 채팅할 대상의 uid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        
        checkChatRoom()
        
        self.tabBarController?.tabBar.isHidden = true
     
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // 시작
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // 종료
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.bottomContraint.constant = keyboardSize.height
        }
        
        UIView.animate(withDuration: 0) {
            self.view.layoutIfNeeded()
        } completion: { complete in
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count
                                                         - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        self.bottomContraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.comments[indexPath.row].uid == uid {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp {
                cell.label_timestamp.text = time.toDayTime
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            
            cell.label_name.text = destinationUserModel?.userName
            cell.label_message.text = self.comments[indexPath.row].message
            cell.label_message.numberOfLines = 0
            
            let url = URL(string: (self.destinationUserModel?.profileImageUrl)!)
            
            cell.imageview_profile.layer.cornerRadius = cell.imageview_profile.frame.width/2
            cell.imageview_profile.clipsToBounds = true
            cell.imageview_profile.kf.setImage(with: url)
            
            if let time = self.comments[indexPath.row].timestamp {
                cell.label_timestamp.text = time.toDayTime
            }

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
                "message": textfield_message.text!,
                "timestamp": ServerValue.timestamp()
            ] as [String : Any]
            
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value) { error, databaseReference in
                self.sendGcm()
                self.textfield_message.text = ""
            }
        }
    }
    
    func sendGcm() {
        let url = "https://fcm.googleapis.com/fcm/send"
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "key=AAAAIeZJXcU:APA91bGk6ArER5pbgF1NTn33lDshYWiPV0gMTfxhE7HemFzy_AOdkm8_WU7QFpRCvGimQys6XFCktDJVscJYj-D-U9VXGJn4zSIkslV5oon2_hQ54Q5aTwwR0owx6nLiEt84_65qy1cU"
        ]
        
        let userName = Auth.auth().currentUser?.displayName
        
        let notificationModel = NotificationModel()
        notificationModel.to = destinationUserModel?.pushToken
        notificationModel.notification.title = userName
        notificationModel.notification.body = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.body = textfield_message.text
        
        let params = notificationModel.toJSON()
        
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { response in
            print(response.result)
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
            self.destinationUserModel = UserModel()
            self.destinationUserModel?.setValuesForKeys(datasnapshot.value as! [String: Any])
            self.getMessageList()
        }
    }
    
    func getMessageList() {
        Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments").observe(DataEventType.value) { datasnapshot in
            self.comments.removeAll()
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let messagedic = item.value as? [String: AnyObject] {
                    let comment = ChatModel.Comment(JSON: messagedic)
                    self.comments.append(comment!)
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

extension Int {
    var toDayTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        
        let date = Date(timeIntervalSince1970: Double(self) / 1000)
        
        return dateFormatter.string(from: date)
    }
}
class MyMessageCell: UITableViewCell {
    
    @IBOutlet var label_message: UILabel!
    @IBOutlet var label_timestamp: UILabel!
}

class DestinationMessageCell: UITableViewCell {
    
    @IBOutlet var label_message: UILabel!
    @IBOutlet var imageview_profile: UIImageView!
    @IBOutlet var label_name: UILabel!
    @IBOutlet var label_timestamp: UILabel!
}
