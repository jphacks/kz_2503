import Foundation

struct Message: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}
