//
//  SearchHistoryRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

// MARK: - Data Models
struct SearchHistoryResponse: Codable {
    let status: Int
    let word: [SearchWord]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case word
        case error
    }
}

struct SearchWord: Codable {
    let value: String
}

enum SearchHistoryResult {
    case success(words: [String])
    case error(message: String)
}

// MARK: - Repository
class SearchHistoryRepository {
    private let apiConfig = APIConfig.shared
    private let userIdRepository = UserIdRepository()
    
    func getSearchHistory() async -> SearchHistoryResult {
        guard let userId = userIdRepository.getCurrentUserId() else {
            return .error(message: "ユーザーIDが見つかりません")
        }
        
        guard let url = URL(string: "\(apiConfig.baseURL)/search/\(userId)") else {
            return .error(message: "無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 共通ヘッダーを設定
        for (key, value) in apiConfig.commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(message: "サーバーからの応答が無効です")
            }
            
            // デバッグ用: レスポンス内容をログ出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("Search History Response Status: \(httpResponse.statusCode)")
                print("Search History Response Body: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let historyResponse = try decoder.decode(SearchHistoryResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                let words = historyResponse.word?.map { $0.value } ?? []
                return .success(words: words)
                
            case 400:
                return .error(message: historyResponse.error ?? "エラーが発生しました")
                
            default:
                return .error(message: "予期しないエラーが発生しました (ステータス: \(httpResponse.statusCode))")
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                print("Search History Decoding Error: \(decodingError)")
                return .error(message: "サーバーからの応答の解析に失敗しました: \(decodingError.localizedDescription)")
            } else {
                print("Search History Network Error: \(error)")
                return .error(message: "ネットワークエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }
}
