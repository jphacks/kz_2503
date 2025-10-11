import Foundation

// === このファイル内だけで使うDTO（モックのJSONにフィット） ===
private struct SearchResponseDTO: Decodable {
    let status: Int
    let recipes: [RecipeDTO]?
}
private struct RecipeDTO: Decodable {
    let recipeId: String
    let title: String
    let chef: String?
    let pictureUrl: String?
}

final class RemoteSearchRecipeRepository: SearchRecipeRepository {
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func all() async throws -> [RecipeSearchResult] { [] }

    func search(keyword: String) async throws -> [RecipeSearchResult] {
        let q = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        var url = APIConfig.baseURL
        url.append(path: "/search/word")
        url.append(path: "/\(encoded)")

        print("[API] GET", url.absoluteString)
        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        

        // 期待: {"status":200,"recipes":[{recipe_id,title,chef,picture_url}]}
        do {
            let root = try decoder.decode(SearchResponseDTO.self, from: data)
            let items = (root.recipes ?? []).map { dto in
                // あなたの RecipeSearchResult のメンバワイズ init をそのまま呼ぶ
                RecipeSearchResult(
                    status: nil,
                    userID: nil,                 // モックには無いので nil
                    categoryID: nil,
                    recipeStatus: nil,
                    title: dto.title,
                    pictureURL: dto.pictureUrl,
                    point: nil,
                    servingCount: nil,
                    recipeMaterial: [],          // 空でOK
                    recipeContent:  []           // 空でOK
                )
            }
            return items
        } catch {
            // 念のためフォールバック: 直配列や results/data キーにも対応
            if let arr = try? decoder.decode([RecipeDTO].self, from: data) {
                return arr.map {
                    RecipeSearchResult(
                        status: nil, userID: nil, categoryID: nil, recipeStatus: nil,
                        title: $0.title, pictureURL: $0.pictureUrl, point: nil, servingCount: nil,
                        recipeMaterial: [], recipeContent: []
                    )
                }
            }
            struct BoxR: Decodable { let results: [RecipeDTO] }
            if let b = try? decoder.decode(BoxR.self, from: data) {
                return b.results.map {
                    RecipeSearchResult(
                        status: nil, userID: nil, categoryID: nil, recipeStatus: nil,
                        title: $0.title, pictureURL: $0.pictureUrl, point: nil, servingCount: nil,
                        recipeMaterial: [], recipeContent: []
                    )
                }
            }
            struct BoxD: Decodable { let data: [RecipeDTO] }
            if let b = try? decoder.decode(BoxD.self, from: data) {
                return b.data.map {
                    RecipeSearchResult(
                        status: nil, userID: nil, categoryID: nil, recipeStatus: nil,
                        title: $0.title, pictureURL: $0.pictureUrl, point: nil, servingCount: nil,
                        recipeMaterial: [], recipeContent: []
                    )
                }
            }
            print("[API] decode error ->", error.localizedDescription)
            throw error
        }
    }
}
