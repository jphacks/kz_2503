import SwiftUI

struct ContentView: View {
    var body: some View {
        @State var selection = 0
        
        TabView(selection: $selection) {
            HomeView()   // ホーム画面
                .tabItem {
                    Label("Page1", systemImage: "house")
                }
                .tag(0)

            RecipeView()   // レシピ詳細画面
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
