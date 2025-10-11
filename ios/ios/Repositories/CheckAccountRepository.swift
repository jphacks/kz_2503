//
//  CheckAccountRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

// MARK: - Data Models
struct CheckAccountResponse: Codable {
    let status: Int
    let userId: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case userId = "user_id"
        case message
    }
}

enum CheckAccountResult {
    case success(userId: String)
    case accountNotFound(message: String)
    case error(message: String)
}

// MARK: - Repository
class CheckAccountRepository {
    private let baseURL = "https://34cfff46e5dd.ngrok-free.app"
    
    func checkAccount(email: String) async -> CheckAccountResult {
        // メールアドレスのバリデーション
        guard isValidEmail(email) else {
            return .error(message: "有効なメールアドレスを入力してください")
        }
        
        // URLエンコード
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return .error(message: "メールアドレスの形式が正しくありません")
        }
        
        let urlString = "\(baseURL)/user/email/\(encodedEmail)"
        
        guard let url = URL(string: urlString) else {
            return .error(message: "無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(message: "サーバーからの応答が無効です")
            }
            
            let decoder = JSONDecoder()
            let checkResponse = try decoder.decode(CheckAccountResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                if let userId = checkResponse.userId {
                    return .success(userId: userId)
                } else {
                    return .error(message: "ユーザーIDが取得できませんでした")
                }
                
            case 202:
                return .accountNotFound(message: checkResponse.message ?? "アカウントが存在しません")
                
            case 400:
                return .error(message: checkResponse.message ?? "エラーが発生しました")
                
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
}
