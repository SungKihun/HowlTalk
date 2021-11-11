//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/11/11.
//

import UIKit
import Firebase

class GroupChatRoomViewController: UIViewController {

    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var button_send: UIButton!
    
    var destinationRoom: String?
    var uid: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: .value) { datasnapshot in
            let dic = datasnapshot.value as! [String: AnyObject]
        }
        
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
