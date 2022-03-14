//
//  SelectFriendViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/11/09.
//

import UIKit
import Firebase
import BEMCheckBox

//MARK: 그룹 채팅방 대상 선택 컨트롤러
class SelectFriendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BEMCheckBoxDelegate {

    @IBOutlet var tableview: UITableView!
    @IBOutlet var button: UIButton!
    
    var array: [UserModel] = []
    
    var users = [String: Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Database.database().reference().child("users").observe(DataEventType.value) { snapShot in
            
            self.array.removeAll()
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapShot.children {
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                
                userModel.setValuesForKeys(fchild.value as! [String: Any])
                
                if userModel.uid == myUid {
                    continue
                }
                
                self.array.append(userModel)
            }
            
            DispatchQueue.main.async {
                self.tableview.reloadData()
            }
        }
        
        button.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        cell.lableName.text = array[indexPath.row].userName
        cell.imageviewProfile.kf.setImage(with: URL(string: array[indexPath.row].profileImageUrl!))
        cell.checkbox.delegate = self
        cell.checkbox.tag = indexPath.row
        
        return cell
    }
    
    func didTap(_ checkBox: BEMCheckBox) {
        // 체크박스가 체크 됐을때 발생하는 이벤트
        if checkBox.on {
            users[self.array[checkBox.tag].uid!] = true
            
        }
        // 체크박스가 체크가 해제 됐을때 발생하는 이벤트
        else {
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
        }
    }

    @objc func createRoom() {
        let myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        
        let nsDic = users as NSDictionary
        
        Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic)
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

class SelectFriendCell: UITableViewCell {
    
    @IBOutlet var checkbox: BEMCheckBox!
    @IBOutlet var imageviewProfile: UIImageView!
    @IBOutlet var lableName: UILabel!
}
