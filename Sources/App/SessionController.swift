import Foundation

/// Orchestrates all components for a session lifecycle.
class SessionController {
    private let config: ClientConfig
    private var sessionManager: SessionManager?
    private var wsClient: WebSocketClient?
    private var webRTCClient: WebRTCClient?
    private var screenCapture: ScreenCaptureManager?
    private var overlayController: OverlayController?
    private var metadataTracker: MetadataTracker?
    
    private var currentSession: CreateSessionResponse?
    private var isRunning = false
    
    init(config: ClientConfig = .default) {
        self.config = config
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        print("[Session] Starting...")
        
        sessionManager = SessionManager(baseURL: config.apiBaseURL)
        
        // 1. Create session
        sessionManager?.createSession(userID: config.userID) { [weak self] result in
            switch result {
            case .success(let session):
                self?.currentSession = session
                self?.connectServices(session: session)
            case .failure(let error):
                print("[Session] Failed to create: \(error)")
                self?.isRunning = false
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        print("[Session] Stopping...")
        
        metadataTracker?.stop()
        screenCapture?.stop()
        webRTCClient?.disconnect()
        wsClient?.disconnect()
        overlayController?.hide()
        
        if let sessionID = currentSession?.id {
            sessionManager?.endSession(id: sessionID) { _ in }
        }
        
        currentSession = nil
        isRunning = false
    }
    
    private func connectServices(session: CreateSessionResponse) {
        print("[Session] Created: \(session.id)")
        
        // 2. Connect WebSocket
        wsClient = WebSocketClient(url: session.wsURL)
        wsClient?.onRecommendations = { [weak self] payload in
            self?.overlayController?.render(recommendations: payload.recommendations)
        }
        wsClient?.onStatus = { status in
            print("[Session] Status: \(status.state)")
        }
        wsClient?.connect()
        
        // 3. Setup overlay
        overlayController = OverlayController()
        overlayController?.show()
        
        // 4. Start screen capture + WebRTC
        webRTCClient = WebRTCClient(signalingURL: session.rtcURL, sessionID: session.id)
        screenCapture = ScreenCaptureManager()
        screenCapture?.onFrame = { [weak self] frame in
            self?.webRTCClient?.sendFrame(frame)
        }
        
        webRTCClient?.connect { [weak self] success in
            if success {
                self?.screenCapture?.start()
                print("[Session] Streaming started")
            } else {
                print("[Session] WebRTC connection failed")
            }
        }
        
        // 5. Start metadata tracking
        metadataTracker = MetadataTracker()
        metadataTracker?.onEvent = { [weak self] metadata in
            self?.wsClient?.sendMetadata(metadata)
        }
        metadataTracker?.start()
    }
}
