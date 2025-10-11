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
    private let aiRepository: AIRepository
    
    init(aiRepository: AIRepository = AIRepository()) {
        self.aiRepository = aiRepository
    }
    
    // MARK: - Published Properties
    var messages: [AIMessage] = [
        .init(role: .assistant, text: "こんにちは。料理の質問に自然に答えます。")
    ]
    var input = ""
    var isSending = false
    var errorMessage: String?
    var availability: AIAvailabilityState = .simulator
    
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
    
    // MARK: - Public Methods
    func onAppear() {
        availability = aiRepository.checkAvailability()
    }
    
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
            aiRepository.speak(response)
        case .error(let error):
            errorMessage = error
        }
    }
    
    func speak(_ text: String) {
        aiRepository.speak(text)
    }
    
    func stopTTS() {
        aiRepository.stopSpeaking()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
