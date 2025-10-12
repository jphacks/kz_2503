//
//  AIChatViewModel.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import Foundation
import Observation

@Observable
final class AIChatViewModel {
    var latestVoiceText: String? // 音声入力でキャプチャした最新の文章
    var latestTriggerWord: String? // 最新のトリガーワード
    
    private let aiRepository: AIRepository
    private let voiceRecognitionService = VoiceRecognitionService()
    
    init(aiRepository: AIRepository = AIRepository()) {
        self.aiRepository = aiRepository
        setupVoiceRecognition()
    }
    
    // MARK: - Properties
    var messages: [AIMessage] = [
        .init(role: .assistant, text: "こんにちは。料理の質問に自然に答えます。")
    ]
    var input = ""
    var isSending = false
    var errorMessage: String?
    var availability: AIAvailabilityState = .simulator
    var isVoiceRecognitionActive = false
    
    // MARK: - Computed Properties
    var availabilityText: String {
        switch availability {
        case .available: return "利用可能"
        case .deviceNotEligible: return "非対応端末"
        case .notEnabled: return "設定で有効化して下さい"
        case .modelNotReady: return "モデル準備中"
        case .simulator: return "シミュレーター（不可）"
        case .other(let text): return text
        }
    }
    
    // MARK: - Setup
    private func setupVoiceRecognition() {
        // 音声認識サービスのコールバック設定
        voiceRecognitionService.onTextCaptured = { [weak self] capturedText in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.latestVoiceText = capturedText
                print("【AIChatViewModel】: 📝 音声テキストを受信: 「\(capturedText)」")
                
                // 自動的にプロンプトとして送信
                Task {
                    await self.sendVoicePrompt(capturedText)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func onAppear() {
        availability = aiRepository.checkAvailability()
    }
    
    /// テキスト入力からメッセージを送信
    @MainActor
    func send() async {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        input = ""
        messages.append(.init(role: .user, text: trimmedInput))
        isSending = true
        defer { isSending = false }
        
        let context = SystemPrompt.CookingContext(recipeTitle: nil, currentStep: nil, servings: nil)
        let result = await aiRepository.sendCookingPrompt(trimmedInput, context: context)

        switch result {
        case .success(let response):
            messages.append(.init(role: .assistant, text: response))
            print("【AIChatViewModel】🤖 AI応答を受信: 「\(response.prefix(50))...」")
            print("【AIChatViewModel】🔊 自動読み上げを開始します")
            aiRepository.speak(response)
        case .error(let error):
            errorMessage = error
            print("【AIChatViewModel】❌ AI応答エラー: \(error)")
        }
    }
    
    /// 音声入力からメッセージを送信（コンテキスト付き）
    @MainActor
    func sendVoicePrompt(_ text: String, context: SystemPrompt.CookingContext = SystemPrompt.CookingContext(), triggerWord: String? = nil) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // ユーザーメッセージを追加（トリガーワード情報を含む）
        messages.append(.init(role: .user, text: trimmedText, triggerWord: triggerWord))
        isSending = true
        defer { isSending = false }
        
        let result = await aiRepository.sendCookingPrompt(trimmedText, context: context)
        
        switch result {
        case .success(let response):
            messages.append(.init(role: .assistant, text: response))
            print("【AIChatViewModel】🤖 AI応答を受信: 「\(response.prefix(50))...」")
            print("【AIChatViewModel】🔊 自動読み上げを開始します")
            aiRepository.speak(response)
        case .error(let error):
            errorMessage = error
            print("【AIChatViewModel】❌ AI応答エラー: \(error)")
        }
    }
    
    /// 音声認識を開始
    func startVoiceRecognition() {
        voiceRecognitionService.startRecognition()
        isVoiceRecognitionActive = true
        print("【AIChatViewModel】: 🎤 音声認識を開始しました")
    }
    
    /// 音声認識を停止
    func stopVoiceRecognition() {
        voiceRecognitionService.stopRecognition()
        isVoiceRecognitionActive = false
        print("【AIChatViewModel】: 🛑 音声認識を停止しました")
    }
    
    /// 最新の音声テキストをクリア
    func clearLatestVoiceText() {
        latestVoiceText = nil
        latestTriggerWord = nil
        voiceRecognitionService.clearLatestText()
    }
    
    func speak(_ text: String) {
        print("【AIChatViewModel】🔊 読み上げボタンから読み上げ: 「\(text.prefix(30))...」")
        aiRepository.speak(text)
    }
    
    func stopTTS() {
        aiRepository.stopSpeaking()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
