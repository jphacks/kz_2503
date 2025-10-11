import Foundation
import Observation

@Observable
final class AIChatViewModel {
    // ここはあなたの実装名に合わせて：
    // もし `DefaultAIChatService` が無いなら `AIChatService()` に変えてください。
    private let ai: AIChatService
    private let tts: TTSService

    init(
        ai: AIChatService = AIChatService(),                // ← Default* が無い想定で統一
        tts: TTSService = AVSpeechTTSService()
    ) {
        self.ai = ai
        self.tts = tts
    }

    var messages: [Message] = [
        .init(role: .assistant, text: "こんにちは。料理の質問に自然に答えます。")
    ]
    var input = ""
    var isSending = false
    var errorMessage: String?
    var availability: AIAvailabilityState = .simulator

    func onAppear() { availability = ai.availability() }

    var availabilityText: String {
        switch availability {
        case .available: "利用可能"
        case .deviceNotEligible: "非対応端末"
        case .notEnabled: "設定で有効化して下さい"
        case .modelNotReady: "モデル準備中"
        case .simulator: "シミュレーター（不可）"
        case .other(let t): t
        }
    }

    @MainActor
    func send() async {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        input = ""
        messages.append(.init(role: .user, text: t))
        isSending = true
        defer { isSending = false }

        do {
            // 料理名などはモデルに"推定させる"（外部データなし）
            let ctx = SystemPrompt.CookingContext(recipeTitle: nil, currentStep: nil, servings: nil)
            let prompt = SystemPrompt.build(ctx: ctx, user: t)

            let a = try await ai.reply(prompt)
            messages.append(.init(role: .assistant, text: a))
            tts.speak(a)
        } catch {
            errorMessage = "AI応答エラー: \(error.localizedDescription)"
        }
    }

    // 任意で直呼びしたいとき
    func speak(_ text: String) { tts.speak(text) }
    func stopTTS() { tts.stop() }
}
