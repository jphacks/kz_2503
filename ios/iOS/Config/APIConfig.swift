import Foundation

enum Environment {
    case development
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://296bd24e2dff.ngrok-free.app"
        case .production:
            return "https://api.wincook.com" // 本番環境のURL
        }
    }
}

struct APIConfig {
    static let shared = APIConfig()
    
    // 現在の環境（開発中はdevelopment、リリース時はproductionに変更）
    private let currentEnvironment: Environment = .development
    
    // ベースURL
    var baseURL: String {
        return currentEnvironment.baseURL
    }
    
    // 共通ヘッダー
    var commonHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true"
        ]
    }
    
    // エンドポイント
    struct Endpoints {
        static let checkAccount = "/user/email"
        static let register = "/user"
        static let updateProfile = "/user/icon"
    }
    
    private init() {}
}
