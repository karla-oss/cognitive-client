import Foundation

struct ClientConfig {
    let apiBaseURL: String
    let userID: String
    let captureFrameRate: Int
    let maxFrameWidth: Int
    let maxFrameHeight: Int
    
    static let `default` = ClientConfig(
        apiBaseURL: UserDefaults.standard.string(forKey: "apiBaseURL") ?? "http://localhost:8090",
        userID: UserDefaults.standard.string(forKey: "userID") ?? UUID().uuidString,
        captureFrameRate: 8,
        maxFrameWidth: 1280,
        maxFrameHeight: 720
    )
}
