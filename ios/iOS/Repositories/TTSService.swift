//
//  TTSService.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import Foundation
import AVFoundation

protocol TTSServiceProtocol: AnyObject {
    func speak(_ text: String)
    func stop()
}

final class TTSService: NSObject, TTSServiceProtocol, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String) {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        
        // 既に読み上げ中の場合は停止してから新しいテキストを読み上げる
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        
        // AVAudioSessionの設定（既に適切な設定がされている場合はスキップ）
        do {
            let currentCategory = session.category
            let needsConfiguration = currentCategory != .playAndRecord
            
            if needsConfiguration {
                print("【TTSService】🔧 AVAudioSessionを設定します")
                try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            }
            
            // セッションが非アクティブな場合のみアクティブ化
            if !session.isOtherAudioPlaying {
                try session.setActive(true, options: [])
            }
        } catch {
            print("【TTSService】❌ AVAudioSession設定エラー: \(error.localizedDescription)")
            // エラーが発生してもTTSは続行を試みる
        }

        let u = AVSpeechUtterance(string: s)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.rate  = AVSpeechUtteranceDefaultSpeechRate
        u.volume = 1.0 // 音量を最大に設定
        
        print("【TTSService】🔊 読み上げ開始: \(s.prefix(30))...")
        synth.speak(u)
    }

    func stop() {
        if synth.isSpeaking {
            print("【TTSService】🛑 読み上げ停止")
            synth.stopSpeaking(at: .immediate)
        }
        // 音声認識が継続できるようにセッションは維持
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("【TTSService】▶️ 読み上げ開始しました")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("【TTSService】✅ 読み上げ完了しました")
        // 音声認識が継続できるようにセッションは維持
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("【TTSService】⏹️ 読み上げキャンセルされました")
    }
}
