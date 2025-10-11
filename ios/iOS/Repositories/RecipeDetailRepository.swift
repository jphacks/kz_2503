//
//  RecipeDetailRepository.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation

struct RecipeDetailResponse: Codable {
    let status: Int
    let recipe: RecipeDetailData
    let message: String?
}

struct RecipeDetailData: Codable {
    let recipeId: String
    let userId: String
    let categoryId: String
    let status: String
    let title: String
    let pictureUrl: String
    let point: String
    let servingCount: Int
    let recipeMaterial: [RecipeDetailMaterial]?
    let recipeContent: [RecipeDetailContent]?
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

struct RecipeDetailMaterial: Codable {
    let materialName: String
    let materialCount: String
    
    enum CodingKeys: String, CodingKey {
        case materialName = "material_name"
        case materialCount = "material_count"
    }
}

struct RecipeDetailContent: Codable {
    let pictureUrl: String?
    let step: Int
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case pictureUrl = "picture_url"
        case step
        case description
    }
}

enum RecipeDetailResult {
    case success(RecipeDetailResponse)
    case error(String)
}

class RecipeDetailRepository {
    private let apiConfig = APIConfig.shared
    
    func getRecipeDetail(recipeId: String) async -> RecipeDetailResult {
        let urlString = "\(apiConfig.baseURL)/recipe/\(recipeId)"
        print("🔍 Fetching recipe detail from: \(urlString)")
        
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
                let recipeDetailResponse = try decoder.decode(RecipeDetailResponse.self, from: data)
                print("✅ Successfully decoded recipe detail for: \(recipeDetailResponse.recipe.title)")
                return .success(recipeDetailResponse)
            } else if httpResponse.statusCode == 400 {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(RecipeDetailResponse.self, from: data)
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
