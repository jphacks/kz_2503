//
//  AIMessage.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import Foundation

struct AIMessage: Identifiable, Codable {
    enum Role: String, Codable { 
        case user, assistant 
    }
    
    let id = UUID()
    let role: Role
    let text: String
    let triggerWord: String? // トリガーワード（ユーザーメッセージの場合のみ使用）
    
    init(role: Role, text: String, triggerWord: String? = nil) {
        self.role = role
        self.text = text
        self.triggerWord = triggerWord
    }
}
