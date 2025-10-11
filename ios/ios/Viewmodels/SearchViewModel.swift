import Foundation
import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var latestRecipes: [String] = ["親子丼", "カルボナーラ", "味噌汁"]

    func submitSearch() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        print("search:", q)
    }

    func clearQuery() { query.removeAll() }
}
