//
//  Message.swift
//  FitClient
//
//  Created by admin8 on 07/11/25.
//

import Foundation

struct Message: Codable {
    let id: String
    let senderId: String
    let senderName: String
    let senderImage: String
    let text: String
    let timestamp: String
    let isFromTrainer: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderImage = "sender_image"
        case text
        case timestamp
        case isFromTrainer = "is_from_trainer"
    }
}

struct ChatData: Codable {
    let clientId: String
    let clientName: String
    let clientImage: String
    let messages: [Message]
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientName = "client_name"
        case clientImage = "client_image"
        case messages
    }
}

struct ChatsResponse: Codable {
    let chats: [ChatData]
}
