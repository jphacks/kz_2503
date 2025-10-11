import Foundation

struct RecipeSearchResult: Codable, Identifiable, Equatable {
    // IDは userID または title が無い時のためにUUIDで埋める
    var id: String { (userID ?? "") + "_" + (title ?? UUID().uuidString) }

    let status: Int?
    let userID: String?
    let categoryID: String?
    let recipeStatus: String?
    let title: String?
    let pictureURL: String?
    let point: String?
    let servingCount: Int?

    // ★ ここを既存型と衝突しない名前に
    let recipeMaterial: [SearchRecipeMaterial]
    let recipeContent:  [SearchRecipeContent]

    enum CodingKeys: String, CodingKey {
        case status
        case userID        = "user_id"
        case categoryID    = "category_id"
        case recipeStatus  = "recipe_status"
        case title
        case pictureURL    = "picture_url"
        case point
        case servingCount  = "serving_count"
        case recipeMaterial = "recipe_material"
        case recipeContent  = "recipe_content"
    }
}

// ★ 既存の Recipe.swift と名前が被らないように
struct SearchRecipeMaterial: Codable, Equatable {
    let materialName:  String?
    let materialCount: String?

    enum CodingKeys: String, CodingKey {
        case materialName  = "material_name"
        case materialCount = "material_count"
    }
}

struct SearchRecipeContent: Codable, Equatable {
    let pictureURL:  String?
    let step:        Int?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case pictureURL  = "picture_url"
        case step
        case description
    }
}
