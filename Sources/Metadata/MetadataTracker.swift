import Cocoa

/// Tracks user interactions: cursor position, clicks, focus changes.
/// Sends metadata events via the onEvent callback.
class MetadataTracker {
    private var mouseMonitor: Any?
    private var clickMonitor: Any?
    private var appObserver: NSObjectProtocol?
    private var isRunning = false
    
    private var sessionID: String = ""
    private var lastCursorSend = Date.distantPast
    private let cursorThrottle: TimeInterval = 0.2 // max 5 cursor events/sec
    
    /// Called with each metadata event
    var onEvent: ((ClientMetadata) -> Void)?
    
    func start(sessionID: String = "") {
        guard !isRunning else { return }
        self.sessionID = sessionID
        isRunning = true
        
        // Track mouse movement
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event)
        }
        
        // Track clicks
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleClick(event)
        }
        
        // Track app focus changes
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleFocusChange(notification)
        }
        
        print("[Metadata] Tracking started")
    }
    
    func stop() {
        guard isRunning else { return }
        
        if let monitor = mouseMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = clickMonitor { NSEvent.removeMonitor(monitor) }
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        mouseMonitor = nil
        clickMonitor = nil
        appObserver = nil
        isRunning = false
        
        print("[Metadata] Tracking stopped")
    }
    
    // MARK: - Handlers
    
    private func handleMouseMove(_ event: NSEvent) {
        let now = Date()
        guard now.timeIntervalSince(lastCursorSend) >= cursorThrottle else { return }
        lastCursorSend = now
        
        guard let screen = NSScreen.main else { return }
        let pos = NSEvent.mouseLocation
        
        let metadata = ClientMetadata(
            type: .cursor,
            sessionID: sessionID,
            timestamp: ISO8601DateFormatter().string(from: now),
            x: pos.x / screen.frame.width,
            y: 1.0 - (pos.y / screen.frame.height) // flip Y to match server coords
        )
        
        onEvent?(metadata)
    }
    
    private func handleClick(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }
        let pos = NSEvent.mouseLocation
        
        let metadata = ClientMetadata(
            type: .click,
            sessionID: sessionID,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            x: pos.x / screen.frame.width,
            y: 1.0 - (pos.y / screen.frame.height)
        )
        
        onEvent?(metadata)
    }
    
    private func handleFocusChange(_ notification: Notification) {
        guard let app = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication) else { return }
        
        let metadata = ClientMetadata(
            type: .focus,
            sessionID: sessionID,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            appName: app.localizedName,
            windowName: nil // Window title requires Accessibility API
        )
        
        onEvent?(metadata)
    }
}
