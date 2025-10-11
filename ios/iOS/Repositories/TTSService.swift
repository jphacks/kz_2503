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
        
        do {
            // 音声認識と同時に使用できるように .playAndRecord を使用
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: [])
        } catch {
            print("【TTSService】❌ AVAudioSession設定エラー: \(error.localizedDescription)")
        }

        let u = AVSpeechUtterance(string: s)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        u.rate  = AVSpeechUtteranceDefaultSpeechRate
        
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
