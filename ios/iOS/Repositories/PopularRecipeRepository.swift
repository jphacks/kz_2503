//
//  PopularRecipeRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

struct PopularRecipeResponse: Codable {
    let status: Int
    let recipes: [PopularRecipe]
    let message: String?
}

struct PopularRecipe: Codable {
    let recipeId: String
    let userId: String
    let categoryId: String
    let status: String
    let title: String
    let pictureUrl: String
    let point: String
    let servingCount: Int
    let recipeMaterial: [String]
    let recipeContent: [String]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case userId = "user_id"
        case categoryId = "category_id"
        case status
        case title
        case pictureUrl = "picture_url"
        case point
        case servingCount = "serving_count"
        case recipeMaterial = "recipe_material"
        case recipeContent = "recipe_content"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum PopularRecipeResult {
    case success([PopularRecipe])
    case error(String)
}

class PopularRecipeRepository {
    private let apiConfig = APIConfig.shared
    
    func getPopularRecipes() async -> PopularRecipeResult {
        let urlString = "\(apiConfig.baseURL)/recipe/popular"
        print("🔍 Fetching popular recipes from: \(urlString)")
        
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
                let popularRecipeResponse = try decoder.decode(PopularRecipeResponse.self, from: data)
                print("✅ Successfully decoded \(popularRecipeResponse.recipes.count) recipes")
                return .success(popularRecipeResponse.recipes)
            } else if httpResponse.statusCode == 400 {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(PopularRecipeResponse.self, from: data)
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