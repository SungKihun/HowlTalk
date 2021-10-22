//
//  ChatModel.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/21.
//

import UIKit

@objcMembers
class ChatModel: NSObject {

    public var users = [String: Bool]() // 채팅방에 참여한 사람들
    public var comments = [String: Comment]() // 채팅방의 대화내용
    
    public class Comment {
        public var uid: String?
        public var message: String?
    }
}
