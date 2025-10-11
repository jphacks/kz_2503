// Viewmodels/SearchViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var titles: [String] = []
    @Published var errorMessage: String?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func submitSearch() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { titles = []; return }
        Task { await searchTitles(q) }
    }

    func clearQuery() {
        query = ""
        titles = []
        errorMessage = nil
    }

    /// GET http://localhost:8080/search/word/{word}
    private func searchTitles(_ keyword: String) async {
        errorMessage = nil
        do {
            var url = APIConfig.baseURL              // 例: http://localhost:8080
            url.append(path: "search")
            url.append(path: "word")
            url.append(path: keyword)                // ← エンコードは append がやってくれる

            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            // レスポンスは `{ status: 200, recipes: [{ recipe_id, title, ... }] }`
            struct Item: Decodable { let title: String }
            struct Root: Decodable { let recipes: [Item] }

            let root = try decoder.decode(Root.self, from: data)
            titles = root.recipes.map { $0.title }   // ← まずはタイトルだけ
        } catch {
            errorMessage = "読み込みに失敗しました"
            titles = []
            print("[Search] error:", error.localizedDescription)
        }
    }
}
