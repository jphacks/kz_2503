//
//  ProfileUpdateRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

// MARK: - Data Models
struct ProfileUpdateRequest: Codable {
    let userId: String
    let icon: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case icon = "Icon"
        case username
    }
}

struct ProfileUpdateResponse: Codable {
    let status: Int
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
    }
}

enum ProfileUpdateResult {
    case success(message: String)
    case error(message: String)
}

// MARK: - Repository
class ProfileUpdateRepository {
    private let baseURL = "https://5a6abf98d0e8.ngrok-free.app"
    
    func updateProfile(userId: String, username: String, icon: String) async -> ProfileUpdateResult {
        // バリデーション
        guard !userId.isEmpty else {
            return .error(message: "ユーザーIDが無効です")
        }
        
        guard !username.isEmpty else {
            return .error(message: "ユーザー名を入力してください")
        }
        
        let requestBody = ProfileUpdateRequest(
            userId: userId,
            icon: icon,
            username: username
        )
        
        guard let url = URL(string: "\(baseURL)/user/icon/\(userId)") else {
            return .error(message: "無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            // デバッグ用: リクエスト内容をログ出力
            if let requestString = String(data: jsonData, encoding: .utf8) {
                print("Profile Update Request Body: \(requestString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(message: "サーバーからの応答が無効です")
            }
            
            // デバッグ用: レスポンス内容をログ出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("Profile Update Response Status: \(httpResponse.statusCode)")
                print("Profile Update Response Body: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let updateResponse = try decoder.decode(ProfileUpdateResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                return .success(message: updateResponse.message ?? "プロフィールを更新しました")
                
            case 400:
                return .error(message: updateResponse.message ?? "エラーが発生しました")
                
            default:
                return .error(message: "予期しないエラーが発生しました (ステータス: \(httpResponse.statusCode))")
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                print("Profile Update Decoding Error: \(decodingError)")
                return .error(message: "サーバーからの応答の解析に失敗しました: \(decodingError.localizedDescription)")
            } else {
                print("Profile Update Network Error: \(error)")
                return .error(message: "ネットワークエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }
}
