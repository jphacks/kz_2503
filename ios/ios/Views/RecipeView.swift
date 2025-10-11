import SwiftUI

struct RecipeView: View {
    let recipeId: String?
    
    @StateObject private var viewModel = RecipeViewModel()
    
    init(recipeId: String? = nil) {
        self.recipeId = recipeId
    }

    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("レシピ詳細")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.toggleHandsFreeSettings()
                        }) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .onAppear {
                    viewModel.loadRecipeData(recipeId: recipeId)
                    viewModel.aiViewModelInstance.onAppear()
                }
        }
    }
    
    // MARK: - Main Content View
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        } else if let recipe = viewModel.recipe {
            recipeContentView(recipe: recipe)
        }
    }
    
    // MARK: - Loading and Error Views
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("レシピを読み込み中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle).foregroundColor(.red)
            Text("エラーが発生しました").font(.headline)
            Text(message).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Recipe Content View
    @ViewBuilder
    private func recipeContentView(recipe: RecipeDetailData) -> some View {
        ScrollViewReader { proxy in
            ZStack {
                // MARK: ScrollView Setup
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    recipeContentBody(recipe: recipe)
                }
                .coordinateSpace(name: "scroll")
                
                scrollBarView
                
                if viewModel.showHandsFreeSettings {
                    handsFreeSettingsOverlay
                }
                
                // AI応答表示（音声入力が有効で、メッセージがある場合）
                if viewModel.handsFreeViewModelInstance.isHandsFreeModeOn && viewModel.voiceInputEnabled && viewModel.aiViewModelInstance.messages.count > 1 {
                    aiResponseOverlay
                }
                
                handsFreeControlsView
            }
            .onChange(of: viewModel.scrollRequest) { oldValue, newValue in
                print("【RecipeView】onChange triggered: oldValue=\(String(describing: oldValue)), newValue=\(String(describing: newValue))")
                if let newRequest = newValue {
                    viewModel.handleScrollRequest(newRequest, proxy: proxy)
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let newPosition = -offset
                viewModel.updateScrollPosition(newPosition)
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                viewModel.updateContentHeight(height)
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear { viewModel.updateVisibleHeight(geometry.size.height) }
                               .onChange(of: geometry.size.height) { _, newHeight in viewModel.updateVisibleHeight(newHeight) }
                }
            )
        }
    }
    
    // MARK: - 分割したUIコンポーネント
    
    @ViewBuilder
    private var scrollBarView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ScrollBarView(
                    currentPosition: viewModel.currentScrollPosition,
                    totalHeight: viewModel.totalContentHeight,
                    visibleHeight: viewModel.visibleHeight
                )
                .frame(width: 8)
                .padding(.trailing, 8)
            }
        }
    }

    @ViewBuilder
    private var handsFreeSettingsOverlay: some View {
        // ZStackで背景を暗くする効果
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { viewModel.showHandsFreeSettings = false }
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "mic.fill").foregroundColor(.blue)
                        Text("ハンズフリーモード設定").font(.headline).fontWeight(.semibold)
                        Spacer()
                        Button(action: { viewModel.showHandsFreeSettings = false }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.title2)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // 自動スクロール設定
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("自動スクロール").font(.subheadline).fontWeight(.medium)
                                Text("ウィンクで自動スクロールします").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $viewModel.autoScrollEnabled).labelsHidden()
                                .onChange(of: viewModel.autoScrollEnabled) { _ in
                                    viewModel.updateAutoScrollEnabled(viewModel.autoScrollEnabled)
                                }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color(.systemGray6)).cornerRadius(8)
                        
                        // 音声入力設定
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("音声入力").font(.subheadline).fontWeight(.medium)
                                Text("音声を文字起こしします").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $viewModel.voiceInputEnabled).labelsHidden()
                                .onChange(of: viewModel.voiceInputEnabled) { _ in
                                    viewModel.updateVoiceInputEnabled(viewModel.voiceInputEnabled)
                                }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color(.systemGray6)).cornerRadius(8)
                    }
                    
                    // ハンズフリーモード開始ボタン
                    Button(action: {
                        viewModel.startHandsFreeMode()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text((viewModel.autoScrollEnabled || viewModel.voiceInputEnabled) ? "ハンズフリーモードを開始" : "自動スクロールまたは音声入力を有効にしてください")
                                .multilineTextAlignment(.center)
                        }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding().background((viewModel.autoScrollEnabled || viewModel.voiceInputEnabled) ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.autoScrollEnabled && !viewModel.voiceInputEnabled)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    @ViewBuilder
    private var aiResponseOverlay: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Text("AI料理アシスタント")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: {
                        // AI応答をクリア（初期メッセージだけを残す）
                        viewModel.aiViewModelInstance.messages = [viewModel.aiViewModelInstance.messages[0]]
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 4)
                
                // 最新のメッセージのみ表示（最後の2件：ユーザーとアシスタント）
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.aiViewModelInstance.messages.suffix(4)) { message in
                            AIMessageBubble(message: message, onSpeak: {
                                print("【RecipeView】🔊 読み上げボタンがタップされました")
                                viewModel.aiViewModelInstance.speak(message.text)
                            })
                        }
                        
                        if viewModel.aiViewModelInstance.isSending {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("考え中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal)
            .padding(.bottom, 80)
        }
    }

    @ViewBuilder
    private var handsFreeControlsView: some View {
        VStack {
            HStack {
                // カメラ映像は自動スクロールがONの時のみ表示
                if viewModel.handsFreeViewModelInstance.isHandsFreeModeOn && viewModel.autoScrollEnabled {
                    CameraView(cameraService: viewModel.handsFreeViewModelInstance.cameraService)
                        .frame(width: 100, height: 150)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.isFaceDetected ? Color.green : Color.red, lineWidth: 3)
                        )
                        .padding()
                }
                Spacer()
                
                // 最新の音声テキストの表示
                if viewModel.handsFreeViewModelInstance.isHandsFreeModeOn && viewModel.voiceInputEnabled, let latestText = viewModel.latestVoiceText {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("音声入力")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                viewModel.handsFreeViewModelInstance.clearLatestVoiceText()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                            }
                        }
                        
                        Text(latestText)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(12)
                    .frame(maxWidth: 250)
                    .background(Color.blue.opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                }
            }
            Spacer()
            HandsFreeControlView(
                isHandsFreeModeOn: viewModel.handsFreeViewModelInstance.isHandsFreeModeOn,
                isFaceDetected: viewModel.isFaceDetected,
                onToggle: {
                    viewModel.handsFreeViewModelInstance.toggleHandsFreeMode()
                }
            )
        }
    }
    
    
    // MARK: - Recipe Content Body
    @ViewBuilder
    private func recipeContentBody(recipe: RecipeDetailData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // スクロールアンカー0（トップ）
            Color.clear.frame(height: 1).id("fixed_anchor_0")
            
            VStack(alignment: .leading, spacing: 16) {
                recipeHeaderView(recipe: recipe)
                recipePointView(recipe: recipe)
                recipeServingView(recipe: recipe)
                recipeMaterialsView(recipe: recipe)
                recipeStepsView(recipe: recipe)
            }
            .padding()
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                }
            )
        }
    }
    
    @ViewBuilder
    private func recipeHeaderView(recipe: RecipeDetailData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            AsyncImage(url: URL(string: recipe.pictureUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Image("mock").resizable().aspectRatio(contentMode: .fill)
                }
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func recipePointView(recipe: RecipeDetailData) -> some View {
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
    private func recipeServingView(recipe: RecipeDetailData) -> some View {
        HStack {
            Text("分量: \(recipe.servingCount)人分")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("ステータス: \(recipe.status)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func recipeMaterialsView(recipe: RecipeDetailData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("材料")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(recipe.recipeMaterial ?? [], id: \.materialName) { material in
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
    private func recipeStepsView(recipe: RecipeDetailData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作り方")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array((recipe.recipeContent ?? []).enumerated()), id: \.element.step) { index, content in
                VStack(spacing: 0) {
                    // 各ステップの前にスクロールアンカーを配置
                    Color.clear.frame(height: 1).id("fixed_anchor_\(index + 1)")
                    recipeStepView(content: content, index: index)
                }
            }
        }
    }
    
    @ViewBuilder
    private func recipeStepView(content: RecipeDetailContent, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("STEP \(content.step)")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.orange).cornerRadius(4)
                Spacer()
            }
            Text(content.description).font(.body)
            if let pictureURL = content.pictureUrl, !pictureURL.isEmpty {
                AsyncImage(url: URL(string: pictureURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Image("mock").resizable().aspectRatio(contentMode: .fill)
                    }
                }
                .frame(height: 150).clipped().cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
}

/// AI応答メッセージのバブル（RecipeView専用の簡易版）
struct AIMessageBubble: View {
    let message: AIMessage
    let onSpeak: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Button(action: onSpeak) {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("読み上げ")
                        }
                        .font(.caption)
                        .foregroundColor(.purple)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(10)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
                Spacer()
            } else {
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(Color.blue)
                .cornerRadius(10)
                
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
    }
}

/// ハンズフリーモードの操作パネル
struct HandsFreeControlView: View {
    let isHandsFreeModeOn: Bool
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
                .padding(.bottom, 8)
                
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
        // コンテンツが画面より大きい場合のみ表示
        if totalHeight > visibleHeight {
            GeometryReader { geometry in
                let scrollBarHeight = (visibleHeight / totalHeight) * geometry.size.height
                let scrollableHeight = geometry.size.height - scrollBarHeight
                let scrollProgress = currentPosition / (totalHeight - visibleHeight)
                let scrollBarPosition = scrollProgress * scrollableHeight
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.6))
                    .frame(height: scrollBarHeight)
                    .offset(y: scrollBarPosition)
            }
        }
    }
}

/// コンテンツ高さを監視するためのPreferenceKey
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// スクロールオフセットを監視するためのPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    RecipeView()
}

