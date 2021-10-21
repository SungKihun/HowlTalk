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
            make.height.equalTo(20)
        }
        
        color = remoteConfig["splash_background"].stringValue
        
        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        signUp.backgroundColor = UIColor(hex: color)
        
        loginButton.addTarget(self, action: #selector(loginEvent), for: .touchUpInside)
        
        signUp.addTarget(self, action: #selector(presentSignUp), for: .touchUpInside)
        
        Auth.auth().addStateDidChangeListener { Auth, User in
            if User != nil {
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
                
                self.present(view, animated: true)
            }
        }
    }
    
    @objc func loginEvent() {
        Auth.auth().signIn(withEmail: email.text!, password: password.text!) { AuthDataResult, Error in
            if Error != nil {
                let alert = UIAlertController(title: "에러", message: Error.debugDescription, preferredStyle: .alert)
                let ok = UIAlertAction(title: "확인", style: .default)
                alert.addAction(ok)
                
                self.present(alert, animated: true)
            }
        }
    }

    @objc func presentSignUp() {
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
