import Foundation

protocol SearchRecipeRepository {
    func all() async throws -> [RecipeSearchResult]
    func search(keyword: String) async throws -> [RecipeSearchResult]
}
