//
//  ViewController.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/18.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    var box = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(box)
        box.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
        box.image = #imageLiteral(resourceName: "loading_icon")
        
    }


}

