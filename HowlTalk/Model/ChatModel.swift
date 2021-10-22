//
//  ChatModel.swift
//  HowlTalk
//
//  Created by 성기훈 on 2021/10/21.
//

import ObjectMapper

@objcMembers
class ChatModel: Mappable {

    public var users = [String: Bool]() // 채팅방에 참여한 사람들
    public var comments = [String: Comment]() // 채팅방의 대화내용
    
    public class Comment: Mappable {
        public var uid: String?
        public var message: String?
        
        public required init?(map: Map) {}
        
        public func mapping(map: Map) {
            uid <- map["uid"]
            message <- map["message"]
        }
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        users <- map["users"]
        comments <- map["comments"]
    }

}
