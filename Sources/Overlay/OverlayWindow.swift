import Cocoa

/// Transparent, click-through window for rendering overlay recommendations.
class OverlayWindow: NSWindow {
    init() {
        // Cover the entire main screen
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        // Transparent and click-through
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Don't show in dock/switcher
        self.isExcludedFromWindowsMenu = true
        
        // Set the content view
        self.contentView = OverlayView(frame: screenFrame)
    }
    
    /// Update the overlay with new recommendations.
    func updateRecommendations(_ recommendations: [Recommendation]) {
        guard let overlayView = contentView as? OverlayView else { return }
        overlayView.recommendations = recommendations
        overlayView.needsDisplay = true
    }
    
    /// Clear all recommendations.
    func clearRecommendations() {
        updateRecommendations([])
    }
}
