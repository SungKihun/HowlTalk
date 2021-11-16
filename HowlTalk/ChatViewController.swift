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
    
    var databaseRef: DatabaseReference?
    var observe: UInt?
    var peopleCount: Int?
    
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
        
        databaseRef?.removeObserver(withHandle: observe!)
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
            
            setReadCount(label: cell.label_read_counter, position: indexPath.row)

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
            
            setReadCount(label: cell.label_read_counter, position: indexPath.row)

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

        // 생성된 채팅방이 없으면
        if chatRoomUid == nil {
            self.sendButton.isEnabled = false
            // 채팅 방 생성
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
    
    // 채팅방 체크
    func checkChatRoom() {
        print(#function)
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/" + uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value) { DataSnapshot in
            for item in DataSnapshot.children.allObjects as! [DataSnapshot] {
                if let chatRoomDic = item.value as? [String: AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomDic)
                    if (chatModel?.users[self.destinationUid!] == true) && (chatModel?.users.count == 2) {
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                        
                        self.getDestinationInfo()
                    }
                }
            }
        }
    }
    
    // 대화 상대 정보 가져오기
    func getDestinationInfo() {
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value) { datasnapshot in
            self.destinationUserModel = UserModel()
            self.destinationUserModel?.setValuesForKeys(datasnapshot.value as! [String: Any])
            self.getMessageList()
        }
    }
    
    func setReadCount(label: UILabel?, position: Int?) {
        let readCount = self.comments[position!].readUsers.count
        
        if self.peopleCount == nil {
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("users").observeSingleEvent(of: .value, with: { datasnapshot in
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
    
    // 메세지 목록 가져오기
    func getMessageList() {
        databaseRef = Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments")
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
    
    @IBOutlet var label_read_counter: UILabel!
    @IBOutlet var label_timestamp: UILabel!
}

class DestinationMessageCell: UITableViewCell {
    
    @IBOutlet var label_message: UILabel!
    @IBOutlet var imageview_profile: UIImageView!
    
    @IBOutlet var label_read_counter: UILabel!
    @IBOutlet var label_name: UILabel!
    @IBOutlet var label_timestamp: UILabel!
}
