import SwiftUI
import Combine

@MainActor
class RecipeViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var recipe: RecipeDetailData?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showHandsFreeSettings = false
    
    // MARK: - Scroll State Properties
    @Published var currentScrollPosition: CGFloat = 0
    @Published var totalContentHeight: CGFloat = 0
    @Published var visibleHeight: CGFloat = 0
    @Published var currentStepIndex: Int = 0
    @Published var isScrolling: Bool = false
    @Published var isWinkScrolling: Bool = false
    @Published var anchorPositions: [Int: CGFloat] = [:]
    @Published var lastScrollPosition: CGFloat = 0
    
    // MARK: - Hands Free Properties
    @Published var autoScrollEnabled = false
    @Published var voiceInputEnabled = false
    @Published var voiceGuidanceEnabled = true
    
    // MARK: - Services
    private let recipeDetailRepository = RecipeDetailRepository()
    private let handsFreeViewModel = HandsFreeViewModel()
    private let aiViewModel = AIChatViewModel()
    
    // MARK: - Private Properties
    private var scrollCooldownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let fixedScrollAmount: CGFloat = 250
    
    init() {
        setupHandsFreeViewModel()
        observeHandsFreeViewModel()
    }
    
    // MARK: - Setup
    private func setupHandsFreeViewModel() {
        // ハンズフリービューモデルのコールバック設定
        handsFreeViewModel.onScrollRequest = { [weak self] request in
            // スクロール要求をHandsFreeViewModelのscrollRequestプロパティに設定
            // ViewのonChangeで処理される
        }
        
        handsFreeViewModel.onFaceDetected = { [weak self] isDetected in
            // 顔検出状態の更新はHandsFreeViewModelで管理
        }
        
        handsFreeViewModel.onVoiceTextCaptured = { [weak self] text in
            self?.handleVoiceTextChange(text)
        }
    }
    
    private func observeHandsFreeViewModel() {
        // HandsFreeViewModelのscrollRequestの変更を監視
        handsFreeViewModel.$scrollRequest
            .sink { [weak self] newRequest in
                self?.scrollRequest = newRequest
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadRecipeData(recipeId: String?) {
        if let recipeId = recipeId {
            print("🔍 Loading recipe with ID: \(recipeId)")
            Task {
                let result = await recipeDetailRepository.getRecipeDetail(recipeId: recipeId)
                
                await MainActor.run {
                    switch result {
                    case .success(let recipeResponse):
                        self.recipe = recipeResponse.recipe
                        self.isLoading = false
                        print("✅ Recipe loaded successfully: \(recipeResponse.recipe.title)")
                    case .error(let message):
                        self.errorMessage = message
                        self.isLoading = false
                        print("❌ Failed to load recipe: \(message)")
                    }
                }
            }
        } else {
            print("🔍 No recipe ID specified")
            errorMessage = "レシピIDが指定されていません"
            isLoading = false
        }
    }
    
    func toggleHandsFreeSettings() {
        showHandsFreeSettings.toggle()
    }
    
    func updateAutoScrollEnabled(_ enabled: Bool) {
        autoScrollEnabled = enabled
        handsFreeViewModel.autoScrollEnabled = enabled
        handsFreeViewModel.updateCameraBasedOnSettings()
    }
    
    func updateVoiceInputEnabled(_ enabled: Bool) {
        voiceInputEnabled = enabled
        handsFreeViewModel.voiceInputEnabled = enabled
        handsFreeViewModel.updateCameraBasedOnSettings()
    }
    
    func startHandsFreeMode() {
        if autoScrollEnabled || voiceInputEnabled {
            handsFreeViewModel.autoScrollEnabled = autoScrollEnabled
            handsFreeViewModel.voiceInputEnabled = voiceInputEnabled
            handsFreeViewModel.toggleHandsFreeMode()
        }
        showHandsFreeSettings = false
    }
    
    // MARK: - Scroll Management
    func handleScrollRequest(_ request: ScrollRequest, proxy: ScrollViewProxy) {
        print("【RecipeViewModel】スクロール要求を受信: \(request.direction == .up ? "⬆️ 上" : "⬇️ 下")")
        
        // レシピが読み込まれていない場合は処理しない
        guard let recipe = recipe else {
            print("【RecipeViewModel】❌ レシピが読み込まれていません。")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handsFreeViewModel.scrollRequest = nil
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
        
        print("【RecipeViewModel】スクロール実行: currentStepIndex=\(currentStepIndex), nextStepIndex=\(nextStepIndex), maxStepIndex=\(maxStepIndex)")
        
        // nextStepIndexが有効な範囲内で、かつ現在位置と異なる場合のみスクロール
        if nextStepIndex != currentStepIndex && nextStepIndex >= 0 && nextStepIndex <= maxStepIndex {
            print("【RecipeViewModel】🎯 アンカー fixed_anchor_\(nextStepIndex) にスクロールします")
            
            // ウィンクによるスクロールであることをマーク
            isWinkScrolling = true
            
            // スクロール抑制を開始
            startScrollSuppression()
            
            // スクロール実行
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo("fixed_anchor_\(nextStepIndex)", anchor: .top)
            }
            currentStepIndex = nextStepIndex
            print("【RecipeViewModel】✅ スクロール完了 → ステップ \(nextStepIndex)")
            
            // スクロール完了後、1.5秒間は抑制を継続し、その後ウィンクフラグをクリア
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isWinkScrolling = false
            }
            stopScrollSuppression(after: 1.5)
        } else {
            if nextStepIndex == currentStepIndex {
                print("【RecipeViewModel】⚠️ すでに同じ位置にいます")
            } else {
                print("【RecipeViewModel】⚠️ これ以上スクロールできません（範囲外）")
            }
        }
        
        // スクロール要求をリセット（次のウィンクを検出できるようにする）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.handsFreeViewModel.scrollRequest = nil
        }
    }
    
    func detectManualScroll(at position: CGFloat) {
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
        if handsFreeViewModel.isScrollingSuppressed {
            stopScrollSuppression(after: 1.5)
            return
        }
        
        print("【RecipeViewModel】📱 手動スクロールを検出（変化量: \(String(format: "%.1f", scrollDelta))px）")
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
                print("【RecipeViewModel】📍 ステップ位置を更新: \(currentStepIndex) → \(clampedStep)")
                currentStepIndex = clampedStep
            }
        }
    }
    
    func updateScrollPosition(_ position: CGFloat) {
        currentScrollPosition = position
        
        // 手動スクロールを検出（プログラムによるスクロールでない場合）
        if !handsFreeViewModel.isScrollingSuppressed {
            detectManualScroll(at: position)
        }
    }
    
    func updateContentHeight(_ height: CGFloat) {
        totalContentHeight = height
    }
    
    func updateVisibleHeight(_ height: CGFloat) {
        visibleHeight = height
    }
    
    // MARK: - Scroll Suppression
    private func startScrollSuppression() {
        handsFreeViewModel.isScrollingSuppressed = true
        print("【RecipeViewModel】🚫 スクロール抑制を開始")
    }
    
    private func stopScrollSuppression(after delay: TimeInterval) {
        scrollCooldownTimer?.invalidate()
        scrollCooldownTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            self.handsFreeViewModel.isScrollingSuppressed = false
            print("【RecipeViewModel】✅ スクロール抑制を解除")
        }
    }
    
    // MARK: - Voice Input Handler
    private func handleVoiceTextChange(_ newText: String?) {
        guard let newText = newText, !newText.isEmpty else { return }
        
        print("【RecipeViewModel】🎤 音声テキストを受信: 「\(newText)」")
        
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
    
    // MARK: - Computed Properties for View
    var handsFreeViewModelInstance: HandsFreeViewModel {
        return handsFreeViewModel
    }
    
    var aiViewModelInstance: AIChatViewModel {
        return aiViewModel
    }
    
    
    var isFaceDetected: Bool {
        return handsFreeViewModel.isFaceDetected
    }
    
    var latestVoiceText: String? {
        return handsFreeViewModel.latestVoiceText
    }
    
    @Published var scrollRequest: ScrollRequest?
}
