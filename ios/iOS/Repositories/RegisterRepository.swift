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

struct RegisterResponse: Codable {
    let status: Int
    let userId: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case userId = "user_id"
        case message
    }
}

enum RegisterResult {
    case success(userId: String)
    case error(message: String)
}

// MARK: - Repository
class RegisterRepository {
    private let baseURL = "https://34cfff46e5dd.ngrok-free.app"
    
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
        
        guard let url = URL(string: "\(baseURL)/user") else {
            return .error(message: "無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(message: "サーバーからの応答が無効です")
            }
            
            let decoder = JSONDecoder()
            let registerResponse = try decoder.decode(RegisterResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                if let userId = registerResponse.userId {
                    return .success(userId: userId)
                } else {
                    return .error(message: "ユーザーIDが取得できませんでした")
                }
                
            case 400:
                return .error(message: registerResponse.message ?? "エラーが発生しました")
                
            default:
                return .error(message: "予期しないエラーが発生しました (ステータス: \(httpResponse.statusCode))")
            }
            
        } catch {
            if error is DecodingError {
                return .error(message: "サーバーからの応答の解析に失敗しました")
            } else {
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
