//
//  LoginViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/19.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signUp: UIButton!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 미리 로그아웃
        try! Auth.auth().signOut()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { make in
            make.right.top.left.equalTo(self.view)
            
            if UIScreen.main.nativeBounds.height == 2436 {
                make.height.equalTo(40)
            } else {
                make.height.equalTo(20)
            }
        }
        
        color = remoteConfig["splash_background"].stringValue
        
        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        signUp.backgroundColor = UIColor(hex: color)
        
        Auth.auth().addStateDidChangeListener { Auth, User in
            if User != nil {
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTabBarController") as! UITabBarController
                
                self.present(view, animated: true)
                
                let uid = Auth.currentUser?.uid
                
                Messaging.messaging().token { token, error in
                  if let error = error {
                    print("Error fetching FCM registration token: \(error)")
                  } else if let token = token {
                    print("FCM registration token: \(token)")
                      Database.database().reference().child("users").child(uid!).updateChildValues(["pushToken": token])
                  }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func loginEvent(_ sender: Any) {
        Auth.auth().signIn(withEmail: email.text!, password: password.text!) { AuthDataResult, Error in
            if Error != nil {
                print(Error.debugDescription)
                let alert = UIAlertController(title: "계정 확인", message: "아이디와 비밀번호를 다시 확인해주세요.", preferredStyle: .alert)
                let ok = UIAlertAction(title: "확인", style: .default)
                alert.addAction(ok)
                
                self.present(alert, animated: true)
            }
        }
    }

    @IBAction func presentSignUp(_ sender: Any) {
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        
        self.present(view, animated: true)
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
