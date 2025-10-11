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
