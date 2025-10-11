//
//  LoginRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

// MARK: - Data Models
struct LoginRequest: Codable {
    let userId: String
    let passwordHash: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case passwordHash = "password_hash"
    }
}

struct LoginResponse: Codable {
    let status: Int
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
    }
}

enum LoginResult {
    case success(message: String)
    case error(message: String)
}

// MARK: - Repository
class LoginRepository {
    private let apiConfig = APIConfig.shared
    
    func login(userId: String, password: String) async -> LoginResult {
        // バリデーション
        guard !userId.isEmpty else {
            return .error(message: "ユーザーIDが無効です")
        }
        
        guard !password.isEmpty else {
            return .error(message: "パスワードを入力してください")
        }
        
        // パスワードハッシュ化（簡易版）
        let passwordHash = hashPassword(password)
        
        let requestBody = LoginRequest(
            userId: userId,
            passwordHash: passwordHash
        )
        
        guard let url = URL(string: "\(apiConfig.baseURL)/user/login/") else {
            return .error(message: "無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 共通ヘッダーを設定
        for (key, value) in apiConfig.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            // デバッグ用: リクエスト内容をログ出力
            if let requestString = String(data: jsonData, encoding: .utf8) {
                print("Login Request Body: \(requestString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(message: "サーバーからの応答が無効です")
            }
            
            // デバッグ用: レスポンス内容をログ出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("Login Response Status: \(httpResponse.statusCode)")
                print("Login Response Body: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let loginResponse = try decoder.decode(LoginResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                return .success(message: loginResponse.message ?? "ログイン完了しました")
                
            case 400:
                return .error(message: loginResponse.message ?? "エラーが発生しました")
                
            default:
                return .error(message: "予期しないエラーが発生しました (ステータス: \(httpResponse.statusCode))")
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                print("Login Decoding Error: \(decodingError)")
                return .error(message: "サーバーからの応答の解析に失敗しました: \(decodingError.localizedDescription)")
            } else {
                print("Login Network Error: \(error)")
                return .error(message: "ネットワークエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func hashPassword(_ password: String) -> String {
        // 簡易的なハッシュ化（実際のアプリではより安全な方法を使用）
        return password.data(using: .utf8)?.base64EncodedString() ?? password
    }
}
