//
//  UserRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

struct UserResponse: Codable {
    let status: Int
    let user: UserData
    let message: String?
}

struct UserData: Codable {
    let userId: String
    let username: String
    let passwordHash: String
    let mailadress: String
    let profile: String
    let icon: String
    let isWink: Bool
    let location: String
    let isAi: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case passwordHash = "password_hash"
        case mailadress
        case profile
        case icon
        case isWink = "is_wink"
        case location
        case isAi = "is_ai"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserInfo: Codable {
    let userId: String
    let username: String
    let mailadress: String
    let profile: String
    let icon: String
    let isWink: Bool
    let location: String
    let isAi: Bool
}

enum UserResult {
    case success(UserInfo)
    case error(String)
}

class UserRepository {
    private let apiConfig = APIConfig.shared
    
    func getUserInfo(userId: String) async -> UserResult {
        let urlString = "\(apiConfig.baseURL)/user/\(userId)"
        print("🔍 Fetching user info from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return .error("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 共通ヘッダーを設定
        for (key, value) in apiConfig.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("📤 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return .error("Invalid response")
            }
            
            print("📥 Response status code: \(httpResponse.statusCode)")
            print("📥 Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let userResponse = try decoder.decode(UserResponse.self, from: data)
                let userInfo = UserInfo(
                    userId: userResponse.user.userId,
                    username: userResponse.user.username,
                    mailadress: userResponse.user.mailadress,
                    profile: userResponse.user.profile,
                    icon: userResponse.user.icon,
                    isWink: userResponse.user.isWink,
                    location: userResponse.user.location,
                    isAi: userResponse.user.isAi
                )
                print("✅ Successfully decoded user info for: \(userInfo.username)")
                return .success(userInfo)
            } else if httpResponse.statusCode == 400 {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(UserResponse.self, from: data)
                print("❌ API Error: \(errorResponse.message ?? "Unknown error")")
                return .error(errorResponse.message ?? "エラーが発生しました")
            } else {
                print("❌ Server error with status code: \(httpResponse.statusCode)")
                return .error("サーバーエラーが発生しました (Status: \(httpResponse.statusCode))")
            }
            
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            return .error("ネットワークエラーが発生しました: \(error.localizedDescription)")
        }
    }
}
