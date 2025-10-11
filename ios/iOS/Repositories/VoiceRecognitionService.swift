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
        print("【音声認識】: 🛑 音声認識を停止しました")
    }
    
    // MARK: - Private Methods
    
    private func startRecording() throws {
        // 既存のタスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // オーディオセッションの設定
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
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
                print("【音声認識】: 📝 \(transcription)")
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
}

