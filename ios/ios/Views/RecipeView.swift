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
    
    // MARK: - Border Animation
    @State private var gradientRotation: Double = 0 // グラデーション枠線の回転角度
    
    // MARK: - Constants
    private let fixedScrollAmount: CGFloat = 250 // 1回のスクロール量（ピクセル）※現在は使用していません

    var body: some View {
        
        ZStack {
            NavigationView {
                mainContent
                    .navigationTitle("レシピ詳細")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showHandsFreeSettings.toggle()
                            }) {
                                Image(systemName: "hand.raised.slash.fill")
                                    .foregroundColor(.theme)
                                    .frame(width: 60)
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
        .overlay(
            // ハンズフリーモードの時のみアニメーションする枠線を表示
            Group {
                if viewModel.isHandsFreeModeOn {
                    AnimatedGradientBorder(rotation: gradientRotation)
                        .onChange(of: viewModel.isHandsFreeModeOn) { _, isOn in
                            if isOn {
                                // ハンズフリーモードON時にアニメーション開始
                                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                                    gradientRotation = 360
                                }
                            } else {
                                // ハンズフリーモードOFF時にリセット
                                gradientRotation = 0
                            }
                        }
                        .onAppear {
                            // 初回表示時にアニメーション開始
                            if viewModel.isHandsFreeModeOn {
                                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                                    gradientRotation = 360
                                }
                            }
                        }
                }
            }
        )
        .ignoresSafeArea()
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
                    integratedAIResponseOverlay
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
                        Image(systemName: "hand.raised.slash.fill").foregroundColor(.theme)
                        Text("ハンズフリーモード設定").font(.headline).fontWeight(.semibold)
                        Spacer()
                        Button(action: { showHandsFreeSettings = false }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.title2)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // 自動スクロール設定
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("ウィンク操作").font(.subheadline).fontWeight(.medium)
                                Text("ウィンクで画面をスクロールできます").font(.caption).foregroundColor(.secondary)
                            }
                            Toggle("", isOn: $autoScrollEnabled).labelsHidden()
                                .onChange(of: autoScrollEnabled) { _ in
                                    viewModel.autoScrollEnabled = autoScrollEnabled
                                    viewModel.updateCameraBasedOnSettings()
                                }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Color.clear).cornerRadius(8)
                        
                        // 音声入力設定
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("ウィンくんと会話").font(.subheadline).fontWeight(.medium)
                                Text("音声入力でウィンくん(AI)と会話できます").font(.caption).foregroundColor(.secondary)
                            }
                            
                            Toggle("", isOn: $voiceInputEnabled).labelsHidden()
                                .onChange(of: voiceInputEnabled) { _ in
                                    viewModel.voiceInputEnabled = voiceInputEnabled
                                    viewModel.updateCameraBasedOnSettings()
                                }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Color.clear).cornerRadius(8)
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
                            Text((autoScrollEnabled || voiceInputEnabled) ? "ハンズフリーモードを開始" : "少なくとも1つを有効にしてください")
                                .multilineTextAlignment(.center)
                        }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding().background((autoScrollEnabled || voiceInputEnabled) ? Color.theme : Color.gray)
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
    private var integratedAIResponseOverlay: some View {
        ZStack {
            // 背景をタップするとメッセージを非表示にする
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    print("【RecipeView】👆 バブルの外がタップされました")
                    // 読み上げ中だったら停止
                    aiViewModel.stopTTS()
                    // メッセージをクリア（初期メッセージだけを残す）
                    if aiViewModel.messages.count > 1 {
                        aiViewModel.messages = [aiViewModel.messages[0]]
                    }
                }
            
            VStack {
                Spacer()
                
                // 統合AI会話バブルを表示（送信中も含む）
                if aiViewModel.messages.count >= 2 || aiViewModel.isSending {
                    let userMessages = aiViewModel.messages.filter { $0.role == .user }
                    let assistantMessages = aiViewModel.messages.filter { $0.role == .assistant }
                    
                    if let lastUserMessage = userMessages.last {
                        VStack(spacing: 12) {
                            AIConversationBubble(
                                userMessage: lastUserMessage,
                                assistantMessage: assistantMessages.last,
                                triggerWord: lastUserMessage.triggerWord,
                                isSending: aiViewModel.isSending
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                        .onTapGesture {
                            // バブル自体をタップした場合は何もしない（外側のタップを防ぐ）
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var handsFreeControlsView: some View {
        VStack {
            HStack {
                // カメラ映像は自動スクロールがONの時のみ表示
                if viewModel.isHandsFreeModeOn && viewModel.autoScrollEnabled {
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.isFaceDetected ? "顔を認識中👀" : "顔を認識できません")
                            .font(.headline)
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                        
                        CameraView(cameraService: viewModel.cameraService)
                            .frame(width: 100, height: 150)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.isFaceDetected ? Color.green : Color.red, lineWidth: 3)
                            )
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            Spacer()
            HandsFreeControlView(
                isHandsFreeModeOn: $viewModel.isHandsFreeModeOn,
                isFaceDetected: viewModel.isFaceDetected,
                autoScrollEnabled: viewModel.autoScrollEnabled,
                onToggle: {
                    // ハンズフリーモードをOFFにする場合、読み上げも停止
                    if viewModel.isHandsFreeModeOn {
                        print("【RecipeView】ハンズフリーモードOFF → 読み上げを停止します")
                        aiViewModel.stopTTS()
                    }
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
        
        // AIにプロンプトを送信（トリガーワード情報を含む）
        Task {
            await aiViewModel.sendVoicePrompt(newText, context: context, triggerWord: viewModel.latestTriggerWord)
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

/// 統合されたAI会話バブル（ユーザーとアシスタントのメッセージを同じバブルに表示）
struct AIConversationBubble: View {
    let userMessage: AIMessage
    let assistantMessage: AIMessage?
    let triggerWord: String?
    let isSending: Bool
    
    init(userMessage: AIMessage, assistantMessage: AIMessage? = nil, triggerWord: String? = nil, isSending: Bool = false) {
        self.userMessage = userMessage
        self.assistantMessage = assistantMessage
        self.triggerWord = triggerWord
        self.isSending = isSending
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ユーザーメッセージ部分
            VStack(alignment: .leading, spacing: 13) {
                Text("ウィンくん \(userMessage.text) >")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // AI応答部分（送信中の場合は「考え中...」を表示）
                if isSending {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        Text("考え中...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } else if let assistantMessage = assistantMessage {
                    Text(assistantMessage.text)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.vertical, 10)
    }
}

/// ハンズフリーモードの操作パネル
struct HandsFreeControlView: View {
    @Binding var isHandsFreeModeOn: Bool
    let isFaceDetected: Bool
    let autoScrollEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack {
            if isHandsFreeModeOn {
                Spacer()
                Button(action: onToggle) {
                    Text("ハンズフリーモード OFF")
                        .fontWeight(.bold)
                        .padding(20)
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
    RecipeView(recipeId: "123e4567-e89b-12d3-a456-426614174001")
}

#Preview("統合AI会話バブル - 塩の量") {
    AIConversationBubble(
        userMessage: AIMessage(
            role: .user,
            text: "塩の量は?",
            triggerWord: "ウィンくん"
        ),
        assistantMessage: AIMessage(
            role: .assistant,
            text: "塩は小さじ3です。大さじ1と同じ量です。"
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("統合AI会話バブル - 調理時間") {
    AIConversationBubble(
        userMessage: AIMessage(
            role: .user,
            text: "この料理はどのくらい時間がかかりますか？",
            triggerWord: "うぃんくん"
        ),
        assistantMessage: AIMessage(
            role: .assistant,
            text: "全体で約30分かかります。下準備に10分、調理に20分です。最初に材料を切っておくと効率的です。"
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("統合AI会話バブル - 考え中") {
    AIConversationBubble(
        userMessage: AIMessage(
            role: .user,
            text: "カレーのコツは？",
            triggerWord: "ウィンくん"
        ),
        assistantMessage: nil,
        triggerWord: "ウィンくん",
        isSending: true
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

/// アニメーションするグラデーション枠線
struct AnimatedGradientBorder: View {
    let rotation: Double
    
    var body: some View {
        ContainerRelativeShape()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .grapfruet,
                        .maskat,
                        .grapfruet
                    ]),
                    center: .center,
                    startAngle: .degrees(rotation),
                    endAngle: .degrees(rotation + 360)
                ),
                lineWidth: 7
            )
    }
}

#Preview("アニメーション枠線") {
    ZStack {
        Color.gray.opacity(0.1)
        AnimatedGradientBorder(rotation: 0)
    }
    .ignoresSafeArea()
}

