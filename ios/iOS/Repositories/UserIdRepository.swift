//
//  UserIdRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftData

class UserIdRepository {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() {
        do {
            modelContainer = try ModelContainer(for: UserIdData.self)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - Write Operations
    
    /// ユーザーIDを保存する（既存のデータがある場合は更新）
    func saveUserId(_ userId: String) {
        // 既存のデータを削除
        deleteAllUserIds()
        
        // 新しいデータを保存
        let userData = UserIdData(userId: userId)
        modelContext.insert(userData)
        
        do {
            try modelContext.save()
            print("UserId saved successfully: \(userId)")
        } catch {
            print("Failed to save userId: \(error)")
        }
    }
    
    /// 全てのユーザーIDデータを削除
    func deleteAllUserIds() {
        let descriptor = FetchDescriptor<UserIdData>()
        
        do {
            let userDataList = try modelContext.fetch(descriptor)
            for userData in userDataList {
                modelContext.delete(userData)
            }
            try modelContext.save()
            print("All userIds deleted successfully")
        } catch {
            print("Failed to delete userIds: \(error)")
        }
    }
    
    // MARK: - Read Operations
    
    /// 現在のユーザーIDを取得
    func getCurrentUserId() -> String? {
        let descriptor = FetchDescriptor<UserIdData>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let userDataList = try modelContext.fetch(descriptor)
            return userDataList.first?.userId
        } catch {
            print("Failed to fetch userId: \(error)")
            return nil
        }
    }
    
    /// 全てのユーザーIDデータを取得
    func getAllUserIds() -> [UserIdData] {
        let descriptor = FetchDescriptor<UserIdData>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch all userIds: \(error)")
            return []
        }
    }
    
    /// ユーザーIDが存在するかチェック
    func hasUserId() -> Bool {
        return getCurrentUserId() != nil
    }
}
