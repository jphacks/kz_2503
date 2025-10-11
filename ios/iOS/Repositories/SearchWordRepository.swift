//
//  SearchWordRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

// MARK: - Data Models
struct SearchWordResponse: Codable {
    let status: Int
    let recipes: [SearchRecipe]?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case recipes
        case message
    }
}

struct SearchRecipe: Codable {
    let recipeId: String
    let title: String
    let chef: String
    let pictureUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case title
        case chef
        case pictureUrl = "picture_url"
    }
}

enum SearchWordResult {
    case success(recipes: [SearchRecipe])
    case error(message: String)
}

// MARK: - Repository
class SearchWordRepository {
    private let apiConfig = APIConfig.shared
    
    func searchWord(_ word: String) async -> SearchWordResult {
        guard !word.isEmpty else {
            return .error(message: "検索ワードを入力してください")
        }
        
        // URLエンコード
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return .error(message: "検索ワードの形式が正しくありません")
        }
        
        guard let url = URL(string: "\(apiConfig.baseURL)/search/word/\(encodedWord)") else {
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
                print("Search Word Response Status: \(httpResponse.statusCode)")
                print("Search Word Response Body: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(SearchWordResponse.self, from: data)
            
            switch httpResponse.statusCode {
            case 200:
                let recipes = searchResponse.recipes ?? []
                return .success(recipes: recipes)
                
            case 400:
                return .error(message: searchResponse.message ?? "エラーが発生しました")
                
            default:
                return .error(message: "予期しないエラーが発生しました (ステータス: \(httpResponse.statusCode))")
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                print("Search Word Decoding Error: \(decodingError)")
                return .error(message: "サーバーからの応答の解析に失敗しました: \(decodingError.localizedDescription)")
            } else {
                print("Search Word Network Error: \(error)")
                return .error(message: "ネットワークエラーが発生しました: \(error.localizedDescription)")
            }
        }
    }
}

