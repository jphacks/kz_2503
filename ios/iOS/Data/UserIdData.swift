//
//  UserIdData.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftData

@Model
class UserIdData {
    var userId: String
    var createdAt: Date
    
    init(userId: String) {
        self.userId = userId
        self.createdAt = Date()
    }
}

