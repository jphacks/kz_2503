import Foundation

enum APIConfig {
    /// Info.plist の `API_BASE_URL` があれば優先。無ければ localhost:8080
    static var baseURL: URL {
        let key = "API_BASE_URL"
        let str = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return URL(string: str ?? "http://localhost:8080")!
    }
}
