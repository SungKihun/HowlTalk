//
//  SignupViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/19.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var email: UITextField!
    @IBOutlet var name: UITextField!
    @IBOutlet var password: UITextField!
    
    @IBOutlet var signUp: UIButton!
    @IBOutlet var cancel: UIButton!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { make in
            make.right.top.left.equalTo(self.view)
            make.height.equalTo(20)
        }
        
        color = remoteConfig["splash_background"].stringValue
        
        statusBar.backgroundColor = UIColor(hex: color)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signUp.backgroundColor = UIColor(hex: color)
        cancel.backgroundColor = UIColor(hex: color)
        
        signUp.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
    }
    
    @objc func imagePicker() {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        // photoLibrary: deprecated 경고. PHPicker 사용
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        
        dismiss(animated: true)
    }
    
    
    @objc func signupEvent() {
        print(#function)
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { AuthDataResult, error in
            let uid = AuthDataResult?.user.uid
            
            let image = self.imageView.image!.jpegData(compressionQuality: 0.1)
            
            let storageRef = Storage.storage().reference().child("userImages").child(uid!)
            let databaseRef = Database.database().reference().child("users").child(uid!)
            
            storageRef.putData(image!, metadata: nil) { (StorageMetadata, Error) in
                storageRef.downloadURL { URL, Error in
                    guard let downloadURL = URL else { return }
                    let values = ["userName": self.name.text!, "profileImageUrl": downloadURL.absoluteString, "uid": Auth.auth().currentUser?.uid]
                    
                    databaseRef.setValue(values) { error, DatabaseReference in
                        if error == nil {
                            self.cancelEvent()
                        }
                    }
                }
            }
        }
    }
    
    @objc func cancelEvent() {
        self.dismiss(animated: true)
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
