import SwiftUI

struct RecipeView: View {
    @State private var recipe: Recipe?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showHandsFreeSettings = false
    @State private var voiceGuidanceEnabled = true
    @State private var autoScrollEnabled = false
    @StateObject private var viewModel = HandsFreeViewModel()
    @State private var currentScrollPosition: CGFloat = 0
    @State private var totalContentHeight: CGFloat = 0
    @State private var visibleHeight: CGFloat = 0
    @State private var currentStepIndex: Int = 0  // 現在のステップインデックス
    
    var body: some View {
        NavigationView {
            mainContent
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
                .onAppear {
                    loadMockData()
                }
        }
        
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(errorMessage)
        } else if let recipe = recipe {
            recipeContentView(recipe: recipe)
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("レシピを読み込み中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("エラーが発生しました")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func recipeContentView(recipe: Recipe) -> some View {
        ScrollViewReader { proxy in
            ZStack {
                ScrollView {
                    recipeContentBody(recipe: recipe)
                }
                
                // スクロールバー
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ScrollBarView(
                            currentPosition: currentScrollPosition,
                            totalHeight: totalContentHeight,
                            visibleHeight: visibleHeight
                        )
                        .frame(width: 8)
                        .padding(.trailing, 8)
                    }
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
                                // ハンズフリーモード開始の処理
                                if autoScrollEnabled {
                                    viewModel.toggleHandsFreeMode()
                                }
                                showHandsFreeSettings = false
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text(autoScrollEnabled ? "ハンズフリーモードを開始" : "自動スクロールを有効にしてください")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(autoScrollEnabled ? Color.blue : Color.gray)
                                .cornerRadius(12)
                            }
                            .disabled(!autoScrollEnabled)
                        }
                        .padding(35)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: -2)
                    }
                    .background(Color.black.opacity(0.3))
                    .ignoresSafeArea()
                }
                
                // 前面の操作UI
                VStack {
                    HStack {
                        // カメラプレビュー
                        if viewModel.isHandsFreeModeOn {
                            CameraView(cameraService: viewModel.cameraService)
                                .frame(width: 100, height: 150)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.isFaceDetected ? Color.green : Color.red, lineWidth: 3)
                                )
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                    HandsFreeControlView(
                        isHandsFreeModeOn: $viewModel.isHandsFreeModeOn,
                        isFaceDetected: viewModel.isFaceDetected,
                        onToggle: {
                            viewModel.toggleHandsFreeMode()
                        }
                    )
                }
                // ViewModelからのスクロール要求を監視
                .onChange(of: viewModel.scrollRequest) { _, newRequest in
                    handleScrollRequest(newRequest, proxy: proxy, recipe: recipe)
                }
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                totalContentHeight = height
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            visibleHeight = geometry.size.height
                        }
                        .onChange(of: geometry.size.height) { _, newHeight in
                            visibleHeight = newHeight
                        }
                }
            )
        }
    }
    
    private func handleScrollRequest(_ request: ScrollRequest?, proxy: ScrollViewProxy, recipe: Recipe) {
        guard let request = request else { return }
        
        print("【RecipeView】📨 スクロール要求を受信: \(request.direction == .up ? "⬆️ 上" : "⬇️ 下")")
        
        let totalSteps = recipe.recipeContent.count
        var newStepIndex = currentStepIndex
        
        switch request.direction {
        case .up:
            // 上にスクロール：前のステップへ
            if currentStepIndex > 0 {
                newStepIndex = currentStepIndex - 1
                print("【RecipeView】スクロール: ステップ \(currentStepIndex) → \(newStepIndex) (上)")
            } else {
                // すでに最初の場合はトップへ
                print("【RecipeView】スクロール: トップへ移動")
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("top", anchor: .top)
                }
                // 要求をリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.scrollRequest = nil
                }
                return
            }
        case .down:
            // 下にスクロール：次のステップへ
            if currentStepIndex < totalSteps - 1 {
                newStepIndex = currentStepIndex + 1
                print("【RecipeView】スクロール: ステップ \(currentStepIndex) → \(newStepIndex) (下)")
            } else {
                print("【RecipeView】⚠️ すでに最後のステップです")
                // 要求をリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.scrollRequest = nil
                }
                return
            }
        }
        
        currentStepIndex = newStepIndex
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo("step_\(newStepIndex)", anchor: .top)
        }
        print("【RecipeView】✅ スクロール実行完了 - ステップ \(newStepIndex)")
        
        // 要求をリセット（次のウィンクを受け付けられるように）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.scrollRequest = nil
        }
    }
    
    @ViewBuilder
    private func recipeContentBody(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // トップのアンカーポイント
            Color.clear.frame(height: 1).id("top")
            
            // レシピタイトルと画像
            recipeHeaderView(recipe: recipe)
            
            // ポイント
            recipePointView(recipe: recipe)
            
            // 分量
            recipeServingView(recipe: recipe)
            
            // 材料
            recipeMaterialsView(recipe: recipe)
            
            // 作り方
            recipeStepsView(recipe: recipe)
        }
        .padding()
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
            }
        )
    }
    
    @ViewBuilder
    private func recipeHeaderView(recipe: Recipe) -> some View {
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
    }
    
    @ViewBuilder
    private func recipePointView(recipe: Recipe) -> some View {
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
    }
    
    @ViewBuilder
    private func recipeServingView(recipe: Recipe) -> some View {
        HStack {
            Text("分量: \(recipe.servingCount)人分")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("ステータス: \(recipe.recipeStatus)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func recipeMaterialsView(recipe: Recipe) -> some View {
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
    }
    
    @ViewBuilder
    private func recipeStepsView(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作り方")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(recipe.recipeContent.enumerated()), id: \.element.step) { index, content in
                recipeStepView(content: content, index: index)
            }
        }
    }
    
    @ViewBuilder
    private func recipeStepView(content: RecipeContent, index: Int) -> some View {
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
        .id("step_\(index)")
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

/// ハンズフリーモードの操作パネル
struct HandsFreeControlView: View {
    @Binding var isHandsFreeModeOn: Bool
    let isFaceDetected: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack {
            if isHandsFreeModeOn {
                VStack(spacing: 8) {
                    Text(isFaceDetected ? "顔を認識中👀" : "顔を認識できません")
                        .font(.headline)
                        .padding(8)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                }
                .opacity(isHandsFreeModeOn ? 1.0 : 0.0)
                
                Button(action: onToggle) {
                    Text("ハンズフリーモード OFF")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

/// スクロールバーコンポーネント
struct ScrollBarView: View {
    let currentPosition: CGFloat
    let totalHeight: CGFloat
    let visibleHeight: CGFloat
    
    var body: some View {
        VStack {
            if totalHeight > visibleHeight {
                let scrollBarHeight = (visibleHeight / totalHeight) * visibleHeight
                let scrollBarPosition = (currentPosition / (totalHeight - visibleHeight)) * (visibleHeight - scrollBarHeight)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.6))
                    .frame(height: scrollBarHeight)
                    .offset(y: scrollBarPosition)
                    .animation(.easeInOut(duration: 0.3), value: scrollBarPosition)
            }
        }
        .frame(height: visibleHeight)
    }
}

/// コンテンツ高さを監視するためのPreferenceKey
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    RecipeView()
}
