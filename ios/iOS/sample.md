import SwiftUI

struct AIChatView: View {
    @State private var vm = AIChatViewModel()

    var body: some View {
        @Bindable var bvm = vm

        VStack(spacing: 0) {
            HStack {
                Text("状態: \(vm.availabilityText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            List(vm.messages) { msg in
                MessageRow(
                    message: msg,
                    onSpeak: (msg.role == .assistant) ? { vm.speak(msg.text) } : nil
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))

            // 入力バー
            HStack(spacing: 8) {
                TextField("メッセージを入力", text: $bvm.input, axis: .vertical)
                    .padding(10)
                Button { Task { await vm.send() } } label: {
                    Image(systemName: "paperplane.fill")
                        .padding(10)
                        .background(Circle().fill(Color.accentColor))
                        .foregroundStyle(.white)
                }
                .disabled(vm.isSending || bvm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            .padding([.horizontal, .bottom])


            Divider()

                .navigationTitle("Cooking Assistant")
                .onAppear { vm.onAppear() }
                .alert("エラー", isPresented: .constant(vm.errorMessage != nil), actions: {
                    Button("OK") { vm.errorMessage = nil }
                }, message: { Text(vm.errorMessage ?? "") })
        }
    }
}

import SwiftUI

struct MessageRow: View {
    let message: Message
    let onSpeak: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .assistant {
                bubble(message.text, isUser: false, showSpeak: onSpeak != nil)
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                bubble(message.text, isUser: true, showSpeak: false)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func bubble(_ text: String, isUser: Bool, showSpeak: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text).font(.body)
            if showSpeak, let onSpeak {
                Button(action: onSpeak) {
                    Label("読み上げ", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isUser ? Color.accentColor : Color.secondary.opacity(0.15))
        )
        .foregroundStyle(isUser ? Color.white : Color.primary)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
    }
}

import SwiftUI

private enum Tab: Int {
    case search, recipe, chat
}

struct ContentView: View {
    @State private var selection: Tab = .search

    var body: some View {
        TabView(selection: $selection) {

            // 1) ホーム/検索
            NavigationStack {
                SearchView()
                    .navigationTitle("Search")
            }
            .tabItem { Label("Page1", systemImage: "house") }
            .tag(Tab.search)

            // 2) レシピ詳細
            NavigationStack {
                RecipeView()
                    .navigationTitle("Recipe")
            }
            .tabItem { Label("Page2", systemImage: "book.pages.fill") }
            .tag(Tab.recipe)

            // 3) AI チャット（TTS付き）
            NavigationStack {
                AIChatView()
                    .navigationTitle("Cooking Assistant")
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.and.text.bubble.fill") }
            .tag(Tab.chat)
        }
    }
}

#Preview { ContentView() }

import Foundation

enum AIAvailabilityState {
    case available, deviceNotEligible, notEnabled, modelNotReady, simulator
    case other(String)
}

import Foundation

struct Message: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}

import Foundation

enum SystemPrompt {
    static let cookingAssistant = """
    あなたは日本語の料理アシスタントです。以下を厳守して、短く明快に答えてください。
    【出力スタイル】
    - 本文は2〜4文。必要に応じて短い手順を1〜3個まで箇条書き可。
    - 最後に必ず `Tip:` を1行、必要時のみ `注意:` を1行。
    - 語尾は断定しすぎず、家庭調理の“目安”として表現（〜程度、〜目安）。
    
    [出力スキーマ]  ※順番厳守／見出し語も厳守
    材料:
    - 箇条書き。各行「食材名 数量（単位）」形式。単位は g / mL / 小さじ / 大さじ / 個 / 本。
    - 人数は文脈から推定、無いときは 2人分で示す（行末に「(2人分)」は不要）。
    手順:
    1. 〜
    2. 〜
    3. 〜
    
    【単位・表記】
    - 分量: g / mL / 小さじ / 大さじ　時間: 分　温度: ℃
    - 火加減: {弱火, 中弱火, 中火, 中強火} を使用（強火は基本禁止）。
    - 比率やレンジで示せる場合は「砂糖：醤油 = 1:1」や「塩 0.8–1.0%」のように幅で。
    【回答方針】
    - ユーザー文から料理名/工程/人数を可能な範囲で**推定**する（外部データなし）。
    - 「砂糖の量は？」「火加減は？」など部分質問には、一般的な**安全側の目安**で即答。
    - 不確実な点はその旨を短く添える（例: 「具材や量で変わりますが…」）。
    - リスク（油ハネ・生肉・乳化・アレルゲン等）は `注意:` に簡潔に明記。
    【禁止】
    - 冗長な前置きや自己言及（「AIとして…」など）は書かない。
    - 画像や表の出力、絵文字、不必要な見出しは使わない。
    """

    struct CookingContext {
        var recipeTitle: String?
        var currentStep: String?
        var servings: Int?
    }

    static func build(ctx: CookingContext, user: String) -> String {
        """
        System: \(cookingAssistant)
        [レシピ文脈]
        タイトル: \(ctx.recipeTitle ?? "不明")
        何人分: \(ctx.servings.map(String.init) ?? "不明")
        現在の手順: \(ctx.currentStep ?? "未指定")
        User: \(user)
        出力形式:
        1) 回答（2〜4文。必要時のみ1〜3個の箇条書き手順を許可）
        2) Tip: ○○
        3) 注意: △△（必要時のみ）
        """
    }
}

import Foundation

#if targetEnvironment(simulator)
// シミュレーターは常に不可
struct AIAvailabilityChecker {
    static func check() -> AIAvailabilityState { .simulator }
}
#else
import FoundationModels

struct AIAvailabilityChecker {
    static func check() -> AIAvailabilityState {
        switch SystemLanguageModel.default.availability {
        case .available: return .available
        case .unavailable(.deviceNotEligible): return .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): return .notEnabled
        case .unavailable(.modelNotReady): return .modelNotReady
        case .unavailable(let reason): return .other("\(reason)")
        }
    }
}
#endif

import Foundation
#if !targetEnvironment(simulator)
import FoundationModels
#endif

final class AIChatService {
    private let session = LanguageModelSession()
    func availability() -> AIAvailabilityState { AIAvailabilityChecker.check() }

    func reply(_ prompt: String) async throws -> String {
        let res: LanguageModelSession.Response<String> = try await session.respond(to: prompt)
        return res.content
    }
}

import AVFoundation

final class AVSpeechTTSService: NSObject, TTSService, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String) {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        try? session.setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        let u = AVSpeechUtterance(string: s)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.rate  = AVSpeechUtteranceDefaultSpeechRate
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

import Foundation

protocol TTSService: AnyObject {
    func speak(_ text: String)
    func stop()
}

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