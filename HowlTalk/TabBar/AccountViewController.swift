//
//  AccountViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/11/09.
//

import UIKit
import Firebase

class AccountViewController: UIViewController {

    @IBOutlet var conditionsCommentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func showAlert(_ sender: Any) {
        let alertController = UIAlertController(title: "상태 메세지", message: nil, preferredStyle: .alert)
        alertController.addTextField { textfield in
            textfield.placeholder = "상태메세지를 입력해주세요."
        }
        
        let ok = UIAlertAction(title: "확인", style: .default) { action in
            if let textfield = alertController.textFields?.first{
                let dic = ["comment": textfield.text!]
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("users").child(uid!).updateChildValues(dic)
            }
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
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
