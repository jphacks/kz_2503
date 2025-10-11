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
