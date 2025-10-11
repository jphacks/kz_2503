import Foundation
import Speech
import AVFoundation

/// 音声認識サービス
class VoiceRecognitionService {
    // MARK: - Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // トリガーワードのバリエーション
    private let triggerWords = [
        "うぃんくん", "ウィンくん", "ウィン君", "うぃん君",
        "winくん", "win君", "ういんくん", "ウイン君", "Wink", "ウィンク",
        "ウインくん", "ういん君", "りんくん", "りん君", "林くん", "君", "ピンク"
    ]
    
    // コマンド検出の状態管理
    private var lastProcessedTriggerEndIndex: String.Index? // 最後に処理したトリガーワードの終了位置
    private var currentCommandText: String? // 現在検出中のコマンドテキスト
    private var processedCommandTexts: Set<String> = [] // 処理済みのコマンドテキスト（重複防止）
    
    // タイムアウト管理
    private var lastTranscriptUpdateTime: Date? // 最後にtranscriptが更新された時刻
    private var currentTriggerPosition: (range: Range<String.Index>, triggerWord: String)? // 現在処理中のトリガー位置
    private let commandTimeout: TimeInterval = 2.0 // コマンド確定までのタイムアウト時間（秒）
    private var timeoutTimer: Timer?
    
    // 現在のトランスクリプト全体を保持
    private var currentTranscript: String = ""
    
    // キャプチャした最新の文章（最新の1つのみ保持）
    private(set) var latestCapturedText: String?
    
    // コールバック
    var onTextCaptured: ((String) -> Void)?
    var onTriggerWordDetected: ((String) -> Void)?
    
    var isRecognizing: Bool {
        return audioEngine.isRunning
    }
    
    // MARK: - Public Methods
    
    /// 音声認識を開始
    func startRecognition() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch authStatus {
                case .authorized:
                    do {
                        try self.startRecording()
                        print("【音声認識】: ✅ 音声認識を開始しました")
                    } catch {
                        print("【音声認識】: ❌ 録音開始エラー: \(error.localizedDescription)")
                    }
                case .denied:
                    print("【音声認識】: ❌ ユーザーが音声認識を拒否しました")
                case .restricted:
                    print("【音声認識】: ❌ この端末では音声認識が制限されています")
                case .notDetermined:
                    print("【音声認識】: ⚠️ 音声認識の権限が未決定です")
                @unknown default:
                    print("【音声認識】: ❌ 不明な認証ステータスです")
                }
            }
        }
    }
    
    /// 音声認識を停止
    func stopRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // タイマーを停止
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        // 状態をリセット
        resetState()
        
        print("【音声認識】: 🛑 音声認識を停止しました")
    }
    
    // MARK: - Private Methods
    
    private func startRecording() throws {
        // 既存のタスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 状態をリセット
        resetState()
        
        // タイムアウトチェックを開始
        startTimeoutCheck()
        
        // オーディオセッションの設定（TTSと同時に使用できるように .playAndRecord を使用）
        let audioSession = AVAudioSession.sharedInstance()
        
        // 既に適切な設定がされている場合は再設定をスキップ
        let currentCategory = audioSession.category
        let needsConfiguration = currentCategory != .playAndRecord
        
        if needsConfiguration {
            print("【音声認識】🔧 AVAudioSessionを設定します")
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        }
        
        // セッションをアクティブ化（既にアクティブな場合はエラーにならない）
        if !audioSession.isOtherAudioPlaying {
            try audioSession.setActive(true, options: [])
        }
        
        // 認識リクエストの作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "認識リクエストの作成に失敗しました"])
        }
        
        // リアルタイムで結果を取得
        recognitionRequest.shouldReportPartialResults = true
        
        // 音声入力ノードの取得
        let inputNode = audioEngine.inputNode
        
        // 認識タスクの開始
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.processTranscription(transcription)
            }
            
            if error != nil {
                print("【音声認識】: ⚠️ エラーまたは認識終了")
                self.stopRecognition()
            }
        }
        
        // オーディオバッファの設定
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // オーディオエンジンの開始
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    // MARK: - Transcription Processing
    
    /// 音声認識結果を処理し、「うぃんくん」をトリガーとして文章を取得
    private func processTranscription(_ transcription: String) {
        print("【音声認識】: 📝 \(transcription)")
        
        // transcriptを更新
        currentTranscript = transcription
        lastTranscriptUpdateTime = Date()
        
        // 全てのトリガーワードの位置を検索
        var allTriggerPositions: [(range: Range<String.Index>, triggerWord: String)] = []
        
        for triggerWord in triggerWords {
            var searchStart = transcription.startIndex
            while searchStart < transcription.endIndex {
                if let range = transcription.range(
                    of: triggerWord,
                    options: [.caseInsensitive],
                    range: searchStart..<transcription.endIndex
                ) {
                    allTriggerPositions.append((range: range, triggerWord: triggerWord))
                    searchStart = range.upperBound
                } else {
                    break
                }
            }
        }
        
        // 位置でソート
        allTriggerPositions.sort { $0.range.lowerBound < $1.range.lowerBound }
        
        // 重複除去（近い位置は同一とみなす）
        var uniqueTriggers: [(range: Range<String.Index>, triggerWord: String)] = []
        for pos in allTriggerPositions {
            let isDuplicate = uniqueTriggers.contains { existing in
                abs(transcription.distance(from: existing.range.lowerBound, to: pos.range.lowerBound)) < 3
            }
            if !isDuplicate {
                uniqueTriggers.append(pos)
            }
        }
        
        // 処理開始位置を決定
        let startSearchIndex = lastProcessedTriggerEndIndex ?? transcription.startIndex
        
        // まだ処理していないトリガーワードを見つける
        guard let currentTrigger = uniqueTriggers.first(where: {
            $0.range.lowerBound >= startSearchIndex
        }) else {
            return
        }
        
        print("【音声認識】: 🎯 キーワード「\(currentTrigger.triggerWord)」を検出しました！")
        
        // トリガーワード検出をコールバックで通知
        DispatchQueue.main.async {
            self.onTriggerWordDetected?(currentTrigger.triggerWord)
        }
        
        // 現在のトリガー位置を保存（タイムアウト時に使用）
        currentTriggerPosition = currentTrigger
        
        // トリガーワードの後のテキストを取得
        let afterTrigger = String(transcription[currentTrigger.range.upperBound...])
        let trimmed = afterTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            // トリガーワードの後に何もない場合は待機
            currentCommandText = nil
            return
        }
        
        // コマンドの終了位置を決定
        var commandEndIndex: String.Index?
        var shouldFinalize = false
        
        // 1. 次のトリガーワードを探す
        let nextTrigger = uniqueTriggers.first { trigger in
            trigger.range.lowerBound > currentTrigger.range.upperBound
        }
        
        if let next = nextTrigger {
            // 次のトリガーワードが見つかった場合、その直前まで
            commandEndIndex = next.range.lowerBound
            shouldFinalize = true
        } else {
            // 次のトリガーワードがない場合、句点などを探す
            let textToSearch = String(transcription[currentTrigger.range.upperBound...])
            
            if let range = textToSearch.range(of: "。") {
                commandEndIndex = transcription.index(currentTrigger.range.upperBound,
                    offsetBy: transcription.distance(from: textToSearch.startIndex, to: range.upperBound))
                shouldFinalize = true
            } else if let range = textToSearch.range(of: "！") {
                commandEndIndex = transcription.index(currentTrigger.range.upperBound,
                    offsetBy: transcription.distance(from: textToSearch.startIndex, to: range.upperBound))
                shouldFinalize = true
            } else if let range = textToSearch.range(of: "？") {
                commandEndIndex = transcription.index(currentTrigger.range.upperBound,
                    offsetBy: transcription.distance(from: textToSearch.startIndex, to: range.upperBound))
                shouldFinalize = true
            } else {
                // 句点もなく、次のトリガーもない場合は仮表示
                // ある程度の長さがあれば仮表示（2秒のタイムアウトで確定される）
                if trimmed.count >= 2 {
                    currentCommandText = trimmed
                }
                return
            }
        }
        
        // コマンドを確定
        if let endIdx = commandEndIndex, shouldFinalize {
            finalizeCommand(from: currentTrigger, to: endIdx)
        }
    }
    
    /// コマンドを確定してログに記録
    private func finalizeCommand(from trigger: (range: Range<String.Index>, triggerWord: String), to endIndex: String.Index) {
        var command = String(currentTranscript[trigger.range.upperBound..<endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "、,"))
        
        // 句点などを除去
        command = command.replacingOccurrences(of: "。", with: "")
        command = command.replacingOccurrences(of: "！", with: "")
        command = command.replacingOccurrences(of: "？", with: "")
        
        guard !command.isEmpty && command.count >= 2 else { return }
        
        // 重複チェック
        if !processedCommandTexts.contains(command) {
            // 最新の文章として保存（上書き）
            latestCapturedText = command
            processedCommandTexts.insert(command)
            
            print("【音声認識】: ━━━━━━━━━━━━━━━━━━━━━━")
            print("【音声認識】: ✅ 文章を取得しました: 「\(command)」")
            print("【音声認識】: 📋 トリガー: \(trigger.triggerWord)")
            print("【音声認識】: ━━━━━━━━━━━━━━━━━━━━━━")
            
            // コールバックで通知
            DispatchQueue.main.async {
                self.onTextCaptured?(command)
            }
        }
        
        // 次のトリガーワードを処理できるように位置を更新
        lastProcessedTriggerEndIndex = trigger.range.upperBound
        
        // 確定したので状態をクリア
        currentCommandText = nil
        currentTriggerPosition = nil
    }
    
    /// 現在の仮表示コマンドをタイムアウトで確定
    private func finalizeCurrentCommandOnTimeout() {
        guard let commandText = currentCommandText,
              !commandText.isEmpty,
              let triggerPos = currentTriggerPosition else {
            return
        }
        
        // トリミングと整形
        var command = commandText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "、,"))
        
        // 句点などを除去
        command = command.replacingOccurrences(of: "。", with: "")
        command = command.replacingOccurrences(of: "！", with: "")
        command = command.replacingOccurrences(of: "？", with: "")
        
        guard command.count >= 2 else { return }
        
        // 重複チェック
        if !processedCommandTexts.contains(command) {
            // 最新の文章として保存（上書き）
            latestCapturedText = command
            processedCommandTexts.insert(command)
            
            print("【音声認識】: ━━━━━━━━━━━━━━━━━━━━━━")
            print("【音声認識】: ⏱️ 文章を取得しました（タイムアウト）: 「\(command)」")
            print("【音声認識】: 📋 トリガー: \(triggerPos.triggerWord)")
            print("【音声認識】: ━━━━━━━━━━━━━━━━━━━━━━")
            
            // コールバックで通知
            DispatchQueue.main.async {
                self.onTextCaptured?(command)
            }
            
            // 次のトリガーワードを処理できるように位置を更新
            lastProcessedTriggerEndIndex = triggerPos.range.upperBound
        }
        
        // 状態をクリア
        currentCommandText = nil
        currentTriggerPosition = nil
        lastTranscriptUpdateTime = nil
    }
    
    // MARK: - Timeout Management
    
    /// タイムアウトチェックを開始
    private func startTimeoutCheck() {
        timeoutTimer?.invalidate()
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // タイムアウトをチェック
            if let lastUpdate = self.lastTranscriptUpdateTime,
               let commandText = self.currentCommandText,
               !commandText.isEmpty {
                
                let elapsed = Date().timeIntervalSince(lastUpdate)
                
                if elapsed >= self.commandTimeout {
                    // 2秒経過したのでコマンドを確定
                    self.finalizeCurrentCommandOnTimeout()
                }
            }
        }
    }
    
    // MARK: - State Management
    
    /// 状態をリセット
    private func resetState() {
        lastProcessedTriggerEndIndex = nil
        currentCommandText = nil
        processedCommandTexts = []
        lastTranscriptUpdateTime = nil
        currentTriggerPosition = nil
        currentTranscript = ""
    }
    
    /// 最新の文章をクリア
    func clearLatestText() {
        latestCapturedText = nil
        resetState()
        print("【音声認識】: 🗑️ 最新の文章をクリアしました")
    }
}
