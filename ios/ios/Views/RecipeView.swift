import SwiftUI

struct RecipeView: View {
    @State private var recipe: Recipe?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showHandsFreeSettings = false
    @State private var voiceGuidanceEnabled = true
    @State private var autoScrollEnabled = false
    
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
                    ZStack {
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
                        
                        // ハンズフリーモード設定オーバーレイ
                        if showHandsFreeSettings {
                            VStack {
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "mic.fill")
                                            .foregroundColor(.blue)
                                        Text("ハンズフリーモード設定")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Button(action: {
                                            showHandsFreeSettings = false
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .font(.title2)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        // 自動スクロール設定
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("自動スクロール")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text("手順に合わせて自動でスクロールします")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Toggle("", isOn: $autoScrollEnabled)
                                                .labelsHidden()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        
                                        // 音声ガイダンス設定
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("音声ガイダンス")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text("料理の手順を音声で案内します")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Toggle("", isOn: $voiceGuidanceEnabled)
                                                .labelsHidden()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    // ハンズフリーモード開始ボタン
                                    Button(action: {
                                        // ハンズフリーモード開始の処理（実装なし）
                                        showHandsFreeSettings = false
                                    }) {
                                        HStack {
                                            Image(systemName: "play.fill")
                                            Text("ハンズフリーモードを開始")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(35)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: -2)
                            }
                            .background(Color.black.opacity(0.3))
                            .ignoresSafeArea()
                        }
                    }
                }
            }
            .navigationTitle("レシピ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showHandsFreeSettings.toggle()
                    }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
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
