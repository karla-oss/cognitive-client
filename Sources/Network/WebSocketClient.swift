import Foundation

/// WebSocket client for bidirectional communication with the signal server.
/// Client → Server: metadata events (cursor, clicks, focus)
/// Server → Client: recommendations, status, errors
class WebSocketClient: NSObject {
    private var webSocket: URLSessionWebSocketTask?
    private let url: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isConnected = false
    
    /// Called when recommendations arrive from server
    var onRecommendations: ((RecommendationPayload) -> Void)?
    /// Called when status update arrives
    var onStatus: ((StatusPayload) -> Void)?
    /// Called on error message from server
    var onError: ((ErrorPayload) -> Void)?
    /// Called on disconnect
    var onDisconnect: (() -> Void)?
    
    init(url: String) {
        self.url = url
        super.init()
    }
    
    func connect() {
        guard let wsURL = URL(string: url) else {
            print("[WS] Invalid URL: \(url)")
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocket = session.webSocketTask(with: wsURL)
        webSocket?.resume()
        isConnected = true
        
        print("[WS] Connecting to \(url)")
        receiveLoop()
    }
    
    func disconnect() {
        isConnected = false
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        print("[WS] Disconnected")
    }
    
    // MARK: - Send metadata to server
    
    func sendMetadata(_ metadata: ClientMetadata) {
        guard isConnected else { return }
        
        guard let data = try? encoder.encode(metadata) else { return }
        let message = URLSessionWebSocketTask.Message.data(data)
        
        webSocket?.send(message) { error in
            if let error = error {
                print("[WS] Send error: \(error)")
            }
        }
    }
    
    // MARK: - Receive loop
    
    private func receiveLoop() {
        webSocket?.receive { [weak self] result in
            guard let self = self, self.isConnected else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveLoop() // continue listening
                
            case .failure(let error):
                print("[WS] Receive error: \(error)")
                self.isConnected = false
                self.onDisconnect?()
                self.attemptReconnect()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .data(let d):
            data = d
        case .string(let s):
            data = Data(s.utf8)
        @unknown default:
            return
        }
        
        guard let serverMsg = try? decoder.decode(ServerMessage.self, from: data) else {
            print("[WS] Failed to decode message")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            switch serverMsg.payload {
            case .recommendations(let payload):
                self?.onRecommendations?(payload)
            case .status(let payload):
                self?.onStatus?(payload)
            case .error(let payload):
                self?.onError?(payload)
            }
        }
    }
    
    // MARK: - Reconnect
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("[WS] Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        let delay = Double(reconnectAttempts) * 2.0 // exponential backoff
        
        print("[WS] Reconnecting in \(delay)s (attempt \(reconnectAttempts))")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[WS] Connected")
        reconnectAttempts = 0
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[WS] Closed: \(closeCode)")
        isConnected = false
        onDisconnect?()
    }
}
