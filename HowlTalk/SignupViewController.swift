//
//  SignupViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/19.
//

import UIKit
import Firebase
import PhotosUI

class SignupViewController: UIViewController, UINavigationControllerDelegate, PHPickerViewControllerDelegate {

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
    }
    
    @objc func imagePicker() {
        let configuration = PHPickerConfiguration()
        let phPicker = PHPickerViewController(configuration: configuration)
        phPicker.delegate = self
        
        self.present(phPicker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: false) {
            let itemProvider = results.first?.itemProvider
            
            if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.imageView.image = image as? UIImage
                    }
                }
            }
        }
    }
    
    @IBAction func signupEvent(_ sender: Any) {
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { AuthDataResult, error in
            let user = AuthDataResult?.user
            let uid = user?.uid

            let image = self.imageView.image!.jpegData(compressionQuality: 0.1)

            user?.createProfileChangeRequest().displayName = self.name.text!
            user?.createProfileChangeRequest().commitChanges(completion: nil)

            let storageRef = Storage.storage().reference().child("userImages").child(uid!)
            let databaseRef = Database.database().reference().child("users").child(uid!)

            storageRef.putData(image!, metadata: nil) { (StorageMetadata, Error) in
                storageRef.downloadURL { URL, Error in
                    guard let downloadURL = URL else { return }
                    let values = ["userName": self.name.text!, "profileImageUrl": downloadURL.absoluteString, "uid": Auth.auth().currentUser?.uid]

                    databaseRef.setValue(values) { error, DatabaseReference in
                        if error == nil {
                            self.cancel.sendActions(for: .touchUpInside)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func cancelEvent(_ sender: Any) {
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
