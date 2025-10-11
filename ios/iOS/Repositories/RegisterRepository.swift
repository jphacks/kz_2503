//
//  RegisterRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

// MARK: - Data Models
struct RegisterRequest: Codable {
    let username: String
    let passwordHash: String
    let mailadress: String
    let location: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case passwordHash = "password_hash"
        case mailadress
        case location
    }
}

struct User: Codable {
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

struct RegisterResponse: Codable {
    let status: Int
    let user: User?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case user
        case message
    }
    
    // デバッグ用の初期化子
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Int.self, forKey: .status)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        
        print("Decoded Response - Status: \(status), UserId: \(user?.userId ?? "nil"), Message: \(message ?? "nil")")
    }
}

enum RegisterResult {
    case success(userId: String)
    case error(message: String)
}

// MARK: - Repository
class RegisterRepository {
    private let apiConfig = APIConfig.shared
    
    func register(username: String, password: String, email: String, location: String = "Japan") async -> RegisterResult {
        // バリデーション
        guard !username.isEmpty else {
            return .error(message: "ユーザー名を入力してください")
        }
        
        guard !password.isEmpty else {
            return .error(message: "パスワードを入力してください")
        }
        
        guard isValidEmail(email) else {
            return .error(message: "有効なメールアドレスを入力してください")
        }
        
        // パスワードハッシュ化（簡易版）
        let passwordHash = hashPassword(password)
        
        let requestBody = RegisterRequest(
            username: username,
            passwordHash: passwordHash,
            mailadress: email,
            location: location
        )
        
        guard let url = URL(string: "\(apiConfig.baseURL)\(APIConfig.Endpoints.register)") else {
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
                print("API Request Body: \(requestString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(message: "サーバーからの応答が無効です")
            }
            
            // デバッグ用: レスポンス内容をログ出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response Status: \(httpResponse.statusCode)")
                print("API Response Body: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let registerResponse = try decoder.decode(RegisterResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                if let user = registerResponse.user {
                    return .success(userId: user.userId)
                } else {
                    return .error(message: "ユーザーIDが取得できませんでした")
                }
                
            case 400:
                return .error(message: registerResponse.message ?? "エラーが発生しました")
                
            default:
                return .error(message: "予期しないエラーが発生しました (ステータス: \(httpResponse.statusCode))")
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                print("Decoding Error: \(decodingError)")
                return .error(message: "サーバーからの応答の解析に失敗しました: \(decodingError.localizedDescription)")
            } else {
                print("Network Error: \(error)")
                return .error(message: "ネットワークエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func hashPassword(_ password: String) -> String {
        // 簡易的なハッシュ化（実際のアプリではより安全な方法を使用）
        return password.data(using: .utf8)?.base64EncodedString() ?? password
    }
}
