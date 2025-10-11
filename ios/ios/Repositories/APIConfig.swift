import Foundation

enum APIConfig {
    static var baseURL: URL {
        let key = "API_BASE_URL"
        let str = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return URL(string: str ?? "http://localhost:8080")!
    }
}
