import Foundation

struct ClientConfig {
    let apiBaseURL: String
    let userID: String
    let captureFrameRate: Int
    let maxFrameWidth: Int
    let maxFrameHeight: Int
    let overlayDisplayDuration: TimeInterval
    
    static let `default`: ClientConfig = {
        let env = EnvLoader.load()
        
        return ClientConfig(
            apiBaseURL: env["API_BASE_URL"]
                ?? UserDefaults.standard.string(forKey: "apiBaseURL")
                ?? "http://localhost:8090",
            userID: env["USER_ID"].flatMap({ $0.isEmpty ? nil : $0 })
                ?? UserDefaults.standard.string(forKey: "userID")
                ?? UUID().uuidString,
            captureFrameRate: Int(env["CAPTURE_FRAME_RATE"] ?? "") ?? 8,
            maxFrameWidth: Int(env["CAPTURE_MAX_WIDTH"] ?? "") ?? 1280,
            maxFrameHeight: Int(env["CAPTURE_MAX_HEIGHT"] ?? "") ?? 720,
            overlayDisplayDuration: Double(env["OVERLAY_DISPLAY_DURATION"] ?? "") ?? 5.0
        )
    }()
}

// MARK: - .env file loader

enum EnvLoader {
    static func load(path: String? = nil) -> [String: String] {
        let filePath = path ?? findEnvFile()
        guard let filePath = filePath,
              let contents = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return [:]
        }
        
        var env: [String: String] = [:]
        
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            
            env[key] = value
        }
        
        return env
    }
    
    private static func findEnvFile() -> String? {
        // Look for .env in the app bundle directory, then working directory
        let candidates = [
            Bundle.main.bundlePath + "/../.env",
            FileManager.default.currentDirectoryPath + "/.env",
            NSHomeDirectory() + "/.cognitive-overlay.env"
        ]
        
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }
}
