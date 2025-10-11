import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var isLoading = true
    private let userIdRepository = UserIdRepository()
    
    var body: some View {
        Group {
            if isLoading {
                // ローディング画面
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("読み込み中...")
                        .padding(.top, 16)
                }
            } else if isLoggedIn {
                // ログイン済みの場合 - メインのタブビュー
                TabView {
                    NavigationStack {
                        SearchView()
                    }
                    .tabItem {
                        Label("検索", systemImage: "magnifyingglass")
                    }
                    .tag(0)

                    RecipeView()
                        .tabItem {
                            Label("レシピ", systemImage: "book.pages.fill")
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
            } else {
                // ログインしていない場合 - StartView
                StartView()
            }
        }
        .onAppear {
            checkLoginStatus()
        }
    }
    
    private func checkLoginStatus() {
        // ローカルにuser_idが保存されているかチェック
        isLoggedIn = userIdRepository.hasUserId()
        isLoading = false
    }
}

#Preview {
    ContentView()
}
