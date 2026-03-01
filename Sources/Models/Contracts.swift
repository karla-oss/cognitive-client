import Foundation

// MARK: - Session Lifecycle

struct CreateSessionRequest: Codable {
    let userID: String
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

struct CreateSessionResponse: Codable {
    let id: String
    let userID: String
    let startTime: String
    let wsURL: String
    let rtcURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case startTime = "start_time"
        case wsURL = "ws_url"
        case rtcURL = "rtc_url"
    }
}

// MARK: - WebRTC Signaling

struct SignalingRequest: Codable {
    let type: String
    let sdp: String
    let sessionID: String
    
    enum CodingKeys: String, CodingKey {
        case type, sdp
        case sessionID = "session_id"
    }
}

struct SignalingResponse: Codable {
    let type: String
    let sdp: String
}

// MARK: - WebSocket: Client → Server (Metadata)

struct ClientMetadata: Codable {
    let type: MetadataType
    let sessionID: String
    let timestamp: String
    var x: Double?
    var y: Double?
    var appName: String?
    var windowName: String?
    var extra: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case sessionID = "session_id"
        case timestamp
        case x, y
        case appName = "app_name"
        case windowName = "window_name"
        case extra
    }
}

enum MetadataType: String, Codable {
    case cursor
    case click
    case scroll
    case focus
    case keypress
}

// MARK: - WebSocket: Server → Client

struct ServerMessage: Codable {
    let type: ServerMessageType
    let sessionID: String
    let timestamp: String
    let payload: ServerPayload
    
    enum CodingKeys: String, CodingKey {
        case type
        case sessionID = "session_id"
        case timestamp
        case payload
    }
}

enum ServerMessageType: String, Codable {
    case recommendations
    case status
    case error
}

enum ServerPayload: Codable {
    case recommendations(RecommendationPayload)
    case status(StatusPayload)
    case error(ErrorPayload)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let recs = try? container.decode(RecommendationPayload.self) {
            self = .recommendations(recs)
            return
        }
        if let status = try? container.decode(StatusPayload.self) {
            self = .status(status)
            return
        }
        if let error = try? container.decode(ErrorPayload.self) {
            self = .error(error)
            return
        }
        
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown payload"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .recommendations(let r): try container.encode(r)
        case .status(let s): try container.encode(s)
        case .error(let e): try container.encode(e)
        }
    }
}

// MARK: - Recommendation

struct RecommendationPayload: Codable {
    let frameHash: String
    let recommendations: [Recommendation]
    let processingMs: Int64
    
    enum CodingKeys: String, CodingKey {
        case frameHash = "frame_hash"
        case recommendations
        case processingMs = "processing_ms"
    }
}

struct Recommendation: Codable, Identifiable {
    let id: String
    let type: RecommendationType
    let text: String
    let confidence: Double
    let priority: Int
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let elementRef: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, text, confidence, priority
        case x, y, width, height
        case elementRef = "element_ref"
    }
}

enum RecommendationType: String, Codable {
    case action
    case info
    case warning
    case hint
}

// MARK: - Status

struct StatusPayload: Codable {
    let state: String
    let message: String?
    let fps: Int?
}

// MARK: - Error

struct ErrorPayload: Codable {
    let code: String
    let message: String
}

// MARK: - Feedback

struct FeedbackRequest: Codable {
    let sessionID: String
    let recommendationID: String
    let accepted: Bool
    let reason: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case recommendationID = "recommendation_id"
        case accepted, reason
    }
}

// MARK: - AnyCodable helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            value = str
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let str = value as? String { try container.encode(str) }
        else if let int = value as? Int { try container.encode(int) }
        else if let double = value as? Double { try container.encode(double) }
        else if let bool = value as? Bool { try container.encode(bool) }
    }
}
