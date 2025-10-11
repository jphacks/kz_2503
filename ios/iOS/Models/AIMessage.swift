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
}
