import SwiftUI

struct RecipeView: View {
    @State private var recipe: Recipe?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("レシピを読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("エラーが発生しました")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let recipe = recipe {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // レシピタイトルと画像
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.title)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                AsyncImage(url: URL(string: recipe.pictureURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        Image("mock")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .empty:
                                        Image("mock")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    @unknown default:
                                        Image("mock")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    }
                                }
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                            }
                            
                            // ポイント
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ポイント")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(recipe.point)
                                    .font(.body)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            // 分量
                            HStack {
                                Text("分量: \(recipe.servingCount)人分")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("ステータス: \(recipe.recipeStatus)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 材料
                            VStack(alignment: .leading, spacing: 8) {
                                Text("材料")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(recipe.recipeMaterial, id: \.materialName) { material in
                                    HStack {
                                        Text(material.materialName)
                                            .font(.body)
                                        Spacer()
                                        Text(material.materialCount)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            
                            // 作り方
                            VStack(alignment: .leading, spacing: 12) {
                                Text("作り方")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(recipe.recipeContent, id: \.step) { content in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("STEP \(content.step)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.orange)
                                                .cornerRadius(4)
                                            Spacer()
                                        }
                                        
                                        Text(content.description)
                                            .font(.body)
                                        
                                        if let pictureURL = content.pictureURL, !pictureURL.isEmpty {
                                            AsyncImage(url: URL(string: pictureURL)) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure(_):
                                                    Image("mock")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .empty:
                                                    Image("mock")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                @unknown default:
                                                    Image("mock")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                }
                                            }
                                            .frame(height: 150)
                                            .clipped()
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("レシピ詳細")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadMockData()
        }
    }
    
    private func loadMockData() {
        guard let url = Bundle.main.url(forResource: "mockRecipe", withExtension: "json") else {
            errorMessage = "JSONファイルが見つかりません"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            recipe = try decoder.decode(Recipe.self, from: data)
            isLoading = false
        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    RecipeView()
}
