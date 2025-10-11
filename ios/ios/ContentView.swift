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

            RecipeView()   // レシピ詳細画面
                .tabItem {
                    Label("Page2", systemImage: "book.pages.fill")
                }
                .tag(1)
            
            NavigationStack {
                AIChatView()
            }
            .tabItem {
                Label("AI Chat", systemImage: "bubble.left.and.text.bubble.fill")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
