import SwiftUI

struct RecipeView: View {
    let recipeId: String?
    
    @State private var recipe: RecipeDetailData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showHandsFreeSettings = false
    @State private var voiceGuidanceEnabled = true
    @State private var autoScrollEnabled = false
    @State private var voiceInputEnabled = false
    @StateObject private var viewModel = HandsFreeViewModel()
    @State private var aiViewModel = AIChatViewModel()
    
    private let recipeDetailRepository = RecipeDetailRepository()
    
    init(recipeId: String? = nil) {
        self.recipeId = recipeId
    }
    
    // MARK: - Scroll State Properties
    @State private var currentScrollPosition: CGFloat = 0 // 現在のスクロール位置(オフセット)
    @State private var totalContentHeight: CGFloat = 0
    @State private var visibleHeight: CGFloat = 0
    @State private var currentStepIndex: Int = 0 // 現在のステップインデックス
    @State private var isScrolling: Bool = false // スクロール中かどうか
    @State private var scrollCooldownTimer: Timer? = nil
    @State private var anchorPositions: [Int: CGFloat] = [:] // 各アンカーのY座標を保存
    @State private var lastScrollPosition: CGFloat = 0 // 前回のスクロール位置
    @State private var isWinkScrolling: Bool = false // ウィンクによるスクロール中かどうか
    
    // MARK: - Constants
    private let fixedScrollAmount: CGFloat = 250 // 1回のスクロール量（ピクセル）※現在は使用していません

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
                    loadRecipeData()
                    aiViewModel.onAppear()
                }
                .onChange(of: viewModel.latestVoiceText) { oldValue, newValue in
                    handleVoiceTextChange(oldValue: oldValue, newValue: newValue)
                }
        }
    }
    
    // MARK: - Main Content View
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
                
                if showHandsFreeSettings {
                    handsFreeSettingsOverlay
                }
                
                // AI応答表示（音声入力が有効で、メッセージがある場合）
                if viewModel.isHandsFreeModeOn && viewModel.voiceInputEnabled && aiViewModel.messages.count > 1 {
                    aiResponseOverlay
                }
                
                handsFreeControlsView
            }
            .onChange(of: viewModel.scrollRequest) { oldValue, newValue in
                print("【RecipeView】onChange triggered: oldValue=\(String(describing: oldValue)), newValue=\(String(describing: newValue))")
                if let newRequest = newValue {
                    handleScrollRequest(newRequest, proxy: proxy)
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let newPosition = -offset
                
                // 手動スクロールを検出（プログラムによるスクロールでない場合）
                if !viewModel.isScrollingSuppressed {
                    detectManualScroll(at: newPosition)
                }
                
                currentScrollPosition = newPosition
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                totalContentHeight = height
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear { visibleHeight = geometry.size.height }
                               .onChange(of: geometry.size.height) { _, newHeight in visibleHeight = newHeight }
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
                    currentPosition: currentScrollPosition,
                    totalHeight: totalContentHeight,
                    visibleHeight: visibleHeight
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
                .onTapGesture { showHandsFreeSettings = false }
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "mic.fill").foregroundColor(.blue)
                        Text("ハンズフリーモード設定").font(.headline).fontWeight(.semibold)
                        Spacer()
                        Button(action: { showHandsFreeSettings = false }) {
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
                            Toggle("", isOn: $autoScrollEnabled).labelsHidden()
                                .onChange(of: autoScrollEnabled) { _ in
                                    viewModel.autoScrollEnabled = autoScrollEnabled
                                    viewModel.updateCameraBasedOnSettings()
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
                            Toggle("", isOn: $voiceInputEnabled).labelsHidden()
                                .onChange(of: voiceInputEnabled) { _ in
                                    viewModel.voiceInputEnabled = voiceInputEnabled
                                    viewModel.updateCameraBasedOnSettings()
                                }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color(.systemGray6)).cornerRadius(8)
                    }
                    
                    // ハンズフリーモード開始ボタン
                    Button(action: {
                        if autoScrollEnabled || voiceInputEnabled {
                            // ViewModelに設定を反映
                            viewModel.autoScrollEnabled = autoScrollEnabled
                            viewModel.voiceInputEnabled = voiceInputEnabled
                            viewModel.toggleHandsFreeMode()
                        }
                        showHandsFreeSettings = false
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text((autoScrollEnabled || voiceInputEnabled) ? "ハンズフリーモードを開始" : "自動スクロールまたは音声入力を有効にしてください")
                                .multilineTextAlignment(.center)
                        }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding().background((autoScrollEnabled || voiceInputEnabled) ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!autoScrollEnabled && !voiceInputEnabled)
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
                        aiViewModel.messages = [aiViewModel.messages[0]]
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 4)
                
                // 最新のメッセージのみ表示（最後の2件：ユーザーとアシスタント）
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(aiViewModel.messages.suffix(4)) { message in
                            AIMessageBubble(message: message, onSpeak: {
                                print("【RecipeView】🔊 読み上げボタンがタップされました")
                                aiViewModel.speak(message.text)
                            })
                        }
                        
                        if aiViewModel.isSending {
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
                if viewModel.isHandsFreeModeOn && viewModel.autoScrollEnabled {
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
                
                // 最新の音声テキストの表示
                if viewModel.isHandsFreeModeOn && viewModel.voiceInputEnabled, let latestText = viewModel.latestVoiceText {
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
                                viewModel.clearLatestVoiceText()
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
                isHandsFreeModeOn: $viewModel.isHandsFreeModeOn,
                isFaceDetected: viewModel.isFaceDetected,
                onToggle: {
                    viewModel.toggleHandsFreeMode()
                }
            )
        }
    }
    
    private func handleScrollRequest(_ request: ScrollRequest, proxy: ScrollViewProxy) {
        print("【RecipeView】スクロール要求を受信: \(request.direction == .up ? "⬆️ 上" : "⬇️ 下")")
        
        // レシピが読み込まれていない場合は処理しない
        guard let recipe = recipe else {
            print("【RecipeView】❌ レシピが読み込まれていません。")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewModel.scrollRequest = nil
            }
            return
        }
        
        // 最大インデックス = レシピステップ数（0はトップ）
        let maxStepIndex = recipe.recipeContent?.count ?? 0
        var nextStepIndex = currentStepIndex
        
        switch request.direction {
        case .up:
            nextStepIndex = max(0, currentStepIndex - 1)
        case .down:
            nextStepIndex = min(maxStepIndex, currentStepIndex + 1)
        }
        
        print("【RecipeView】スクロール実行: currentStepIndex=\(currentStepIndex), nextStepIndex=\(nextStepIndex), maxStepIndex=\(maxStepIndex)")
        
        // nextStepIndexが有効な範囲内で、かつ現在位置と異なる場合のみスクロール
        if nextStepIndex != currentStepIndex && nextStepIndex >= 0 && nextStepIndex <= maxStepIndex {
            print("【RecipeView】🎯 アンカー fixed_anchor_\(nextStepIndex) にスクロールします")
            
            // ウィンクによるスクロールであることをマーク
            isWinkScrolling = true
            
            // スクロール抑制を開始
            startScrollSuppression()
            
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo("fixed_anchor_\(nextStepIndex)", anchor: .top)
            }
            currentStepIndex = nextStepIndex
            print("【RecipeView】✅ スクロール完了 → ステップ \(nextStepIndex)")
            
            // スクロール完了後、1.5秒間は抑制を継続し、その後ウィンクフラグをクリア
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isWinkScrolling = false
            }
            stopScrollSuppression(after: 1.5)
        } else {
            if nextStepIndex == currentStepIndex {
                print("【RecipeView】⚠️ すでに同じ位置にいます")
            } else {
                print("【RecipeView】⚠️ これ以上スクロールできません（範囲外）")
            }
        }
        
        // スクロール要求をリセット（次のウィンクを検出できるようにする）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewModel.scrollRequest = nil
        }
    }
    
    private func startScrollSuppression() {
        viewModel.isScrollingSuppressed = true
        print("【RecipeView】🚫 スクロール抑制を開始")
    }
    
    private func stopScrollSuppression(after delay: TimeInterval) {
        scrollCooldownTimer?.invalidate()
        scrollCooldownTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            self.viewModel.isScrollingSuppressed = false
            print("【RecipeView】✅ スクロール抑制を解除")
        }
    }
    
    private func detectManualScroll(at position: CGFloat) {
        // ウィンクによるスクロール中は手動スクロールとして扱わない
        guard !isWinkScrolling else { return }
        
        // スクロール位置の変化が小さい場合は無視（慣性スクロールなどのノイズ）
        let scrollDelta = abs(position - lastScrollPosition)
        guard scrollDelta > 5 else {
            lastScrollPosition = position
            return
        }
        
        lastScrollPosition = position
        
        // 手動スクロールが検出されたら、一時的に抑制を有効化
        // これにより、スクロール中の誤検出を防ぐ
        guard let recipe = recipe else { return }
        
        // 既に抑制中の場合はタイマーを延長
        if viewModel.isScrollingSuppressed {
            stopScrollSuppression(after: 1.5)
            return
        }
        
        print("【RecipeView】📱 手動スクロールを検出（変化量: \(String(format: "%.1f", scrollDelta))px）")
        startScrollSuppression()
        
        // 1.5秒後に抑制を解除
        stopScrollSuppression(after: 1.5)
        
        // 簡易的なステップ推定（コンテンツの高さベース）
        // より正確には各アンカーの実際の位置を使用する必要があるが、
        // ここでは均等分割で近似
        if totalContentHeight > 0 {
            let stepCount = (recipe.recipeContent?.count ?? 0) + 1 // +1 for the top section
            let estimatedStepHeight = totalContentHeight / CGFloat(stepCount)
            let estimatedStep = Int(round(position / estimatedStepHeight))
            let clampedStep = max(0, min(recipe.recipeContent?.count ?? 0, estimatedStep))
            
            if clampedStep != currentStepIndex {
                print("【RecipeView】📍 ステップ位置を更新: \(currentStepIndex) → \(clampedStep)")
                currentStepIndex = clampedStep
            }
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
    
    // MARK: - Voice Input Handler
    private func handleVoiceTextChange(oldValue: String?, newValue: String?) {
        guard let newText = newValue, !newText.isEmpty else { return }
        guard oldValue != newValue else { return }
        
        print("【RecipeView】🎤 音声テキストを受信: 「\(newText)」")
        
        // レシピコンテキストを作成
        let context = SystemPrompt.CookingContext(
            recipeTitle: recipe?.title,
            currentStep: getCurrentStepDescription(),
            servings: recipe?.servingCount
        )
        
        // AIにプロンプトを送信
        Task {
            await aiViewModel.sendVoicePrompt(newText, context: context)
        }
    }
    
    private func getCurrentStepDescription() -> String? {
        guard let recipe = recipe else { return nil }
        guard currentStepIndex > 0, let contents = recipe.recipeContent else { return nil }
        let index = currentStepIndex - 1
        guard index < contents.count else { return nil }
        return "STEP \(contents[index].step): \(contents[index].description)"
    }
    
    private func loadRecipeData() {
        // recipe_idが指定されている場合は、APIからデータを取得
        if let recipeId = recipeId {
            print("🔍 Loading recipe with ID: \(recipeId)")
            Task {
                let result = await recipeDetailRepository.getRecipeDetail(recipeId: recipeId)
                
                await MainActor.run {
                    switch result {
                    case .success(let recipeResponse):
                        recipe = recipeResponse.recipe
                        isLoading = false
                        print("✅ Recipe loaded successfully: \(recipeResponse.recipe.title)")
                    case .error(let message):
                        errorMessage = message
                        isLoading = false
                        print("❌ Failed to load recipe: \(message)")
                    }
                }
            }
        } else {
            // recipe_idが指定されていない場合
            print("🔍 No recipe ID specified")
            errorMessage = "レシピIDが指定されていません"
            isLoading = false
        }
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

