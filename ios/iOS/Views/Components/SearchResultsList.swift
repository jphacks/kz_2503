import SwiftUI

struct SearchResultsList: View {
    let items: [RecipeSearchResult]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(items) { r in
                RecipeRow(title: r.title ?? "（タイトル不明）",
                          materials: r.recipeMaterial.compactMap{$0.materialName})
            }
        }
        .padding(.vertical, 12)
    }
}
