//
//  MainViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/21.
//

import UIKit
import SnapKit
import Firebase
import Kingfisher
import SwiftUI

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var array: [UserModel] = []
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(PeopleViewTableCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.bottom.left.right.equalTo(view)
        }
        
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
                self.tableView.reloadData()
            }
        }
        
        // 그룹 채팅방 대상 선택 제거
//        let selectFriendButton = UIButton()
//        view.addSubview(selectFriendButton)
//        selectFriendButton.snp.makeConstraints { make in
//            make.bottom.equalTo(view).offset(-70)
//            make.right.equalTo(view).offset(-20)
//            make.width.height.equalTo(50)
//        }
//        selectFriendButton.backgroundColor = UIColor.black
//        selectFriendButton.addTarget(self, action: #selector(showSelectFriendController), for: .touchUpInside)
//        selectFriendButton.layer.cornerRadius = 25
//        selectFriendButton.layer.masksToBounds = true
    }
    
    // MARK: 그룹 채팅방 대상 선택화면 이동 세그웨이
//    @objc func showSelectFriendController() {
//        self.performSegue(withIdentifier: "SelectFriendSegue", sender: nil)
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PeopleViewTableCell
        
        let imageview = cell.imageview!
        
        imageview.snp.makeConstraints { make in
            make.centerY.equalTo(cell)
            make.left.equalTo(cell).offset(10)
            make.height.width.equalTo(50)
        }
        
        let url = URL(string: array[indexPath.row].profileImageUrl!)
        
        imageview.layer.cornerRadius = 50/2
        imageview.clipsToBounds = true
        imageview.kf.setImage(with: url)
        
        let label = cell.label!
        
        label.snp.makeConstraints { m in
            m.centerY.equalTo(cell)
            m.left.equalTo(imageview.snp.right).offset(20)
        }
        
        label.text = array[indexPath.row].userName
        
        let label_comment = cell.label_comment!
        label_comment.snp.makeConstraints { make in
            make.right.equalTo(cell.uiview_comment_background)
            make.centerY.equalTo(cell.uiview_comment_background)
        }
        if let comment = array[indexPath.row].comment{
            label_comment.text = comment
        }
        cell.uiview_comment_background.snp.makeConstraints { make in
            make.right.equalTo(cell).offset(-10)
            make.centerY.equalTo(cell)
            if let count = label_comment.text?.count {
                make.width.equalTo(count * 10)
            } else {
                make.width.equalTo(0)
            }
            make.height.equalTo(30)
        }
        cell.uiview_comment_background.backgroundColor = UIColor.gray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // 유저를 선택하면 1:1 채팅으로 이동
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController else { return }
        view.destinationUid = self.array[indexPath.row].uid
        
        self.navigationController?.pushViewController(view, animated: true)
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

class PeopleViewTableCell: UITableViewCell {
    
    var imageview: UIImageView! = UIImageView()
    var label: UILabel! = UILabel()
    var label_comment: UILabel! = UILabel()
    var uiview_comment_background: UIView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(imageview)
        self.addSubview(label)
        self.addSubview(uiview_comment_background)
        self.addSubview(label_comment)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
