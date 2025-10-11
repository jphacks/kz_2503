import SwiftUI

private enum Tab: Int {
    case search, recipe, chat
}

struct ContentView: View {
    @State private var selection: Tab = .search

    var body: some View {
        TabView(selection: $selection) {

            // 1) ホーム/検索
            NavigationStack {
                SearchView()
                    .navigationTitle("Search")
            }
            .tabItem { Label("Page1", systemImage: "house") }
            .tag(Tab.search)

            // 2) レシピ詳細
            NavigationStack {
                RecipeView()
                    .navigationTitle("Recipe")
            }
            .tabItem { Label("Page2", systemImage: "book.pages.fill") }
            .tag(Tab.recipe)

            // 3) AI チャット（TTS付き）
            NavigationStack {
                AIChatView()
                    .navigationTitle("Cooking Assistant")
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.and.text.bubble.fill") }
            .tag(Tab.chat)
        }
    }
}

#Preview { ContentView() }
