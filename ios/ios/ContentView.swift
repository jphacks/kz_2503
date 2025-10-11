import SwiftUI

struct ContentView: View {
    var body: some View {
        @State var selection = 0
        
        TabView(selection: $selection) {
            StartView()   // ホーム画面
                .tabItem {
                    Label("Page1", systemImage: "house")
                }
                .tag(0)

            RecipeView(recipeId: "123e4567-e89b-12d3-a456-426614174001")   // レシピ詳細画面
                .tabItem {
                    Label("Page2", systemImage: "book.pages.fill")
                }
                .tag(1)
            }
    }
}

#Preview {
    ContentView()
}
