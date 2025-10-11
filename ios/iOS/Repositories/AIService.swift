//
//  AIService.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

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

#if !targetEnvironment(simulator)
import FoundationModels
#endif

final class AIService {
    private let session = LanguageModelSession()
    
    func availability() -> AIAvailabilityState { 
        AIAvailabilityChecker.check() 
    }

    func reply(_ prompt: String) async throws -> String {
        let res: LanguageModelSession.Response<String> = try await session.respond(to: prompt)
        return res.content
    }
}
