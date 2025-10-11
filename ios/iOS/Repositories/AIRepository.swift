//
//  AIRepository.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import Foundation

enum AIResult {
    case success(String)
    case error(String)
}

class AIRepository {
    private let aiService: AIService
    private let ttsService: TTSServiceProtocol
    
    init(
        aiService: AIService = AIService(),
        ttsService: TTSServiceProtocol = TTSService()
    ) {
        self.aiService = aiService
        self.ttsService = ttsService
    }
    
    // MARK: - AI機能
    
    /// AIの利用可能性をチェック
    func checkAvailability() -> AIAvailabilityState {
        return aiService.availability()
    }
    
    /// プロンプトを送信してAIからの応答を取得
    func sendPrompt(_ prompt: String) async -> AIResult {
        do {
            let response = try await aiService.reply(prompt)
            return .success(response)
        } catch {
            return .error("AI応答エラー: \(error.localizedDescription)")
        }
    }
    
    /// 料理アシスタント用のプロンプトを送信
    func sendCookingPrompt(_ userMessage: String, context: SystemPrompt.CookingContext = SystemPrompt.CookingContext()) async -> AIResult {
        let prompt = SystemPrompt.build(ctx: context, user: userMessage)
        return await sendPrompt(prompt)
    }
    
    // MARK: - TTS機能
    
    /// テキストを音声で読み上げ
    func speak(_ text: String) {
        ttsService.speak(text)
    }
    
    /// 音声読み上げを停止
    func stopSpeaking() {
        ttsService.stop()
    }
    
    // MARK: - 便利メソッド
    
    /// 利用可能性のテキスト表現を取得
    func getAvailabilityText() -> String {
        switch checkAvailability() {
        case .available: return "利用可能"
        case .deviceNotEligible: return "非対応端末"
        case .notEnabled: return "設定で有効化して下さい"
        case .modelNotReady: return "モデル準備中"
        case .simulator: return "シミュレーター（不可）"
        case .other(let text): return text
        }
    }
}