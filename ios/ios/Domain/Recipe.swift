import Foundation

struct Recipe: Codable {
    let status: Int
    let userID: String
    let categoryID: String
    let recipeStatus: String
    let title: String
    let pictureURL: String
    let point: String
    let servingCount: Int
    let recipeMaterial: [RecipeMaterial]
    let recipeContent: [RecipeContent]
    
    enum CodingKeys: String, CodingKey {
        case status
        case userID = "user_id"
        case categoryID = "category_id"
        case recipeStatus = "recipe_status"
        case title
        case pictureURL = "picture_url"
        case point
        case servingCount = "serving_count"
        case recipeMaterial = "recipe_material"
        case recipeContent = "recipe_content"
    }
}

struct RecipeMaterial: Codable {
    let materialName: String
    let materialCount: String
    
    enum CodingKeys: String, CodingKey {
        case materialName = "material_name"
        case materialCount = "material_count"
    }
}

struct RecipeContent: Codable {
    let pictureURL: String?
    let step: Int
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case pictureURL = "picture_url"
        case step
        case description
    }
}
