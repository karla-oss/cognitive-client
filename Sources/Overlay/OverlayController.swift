import Cocoa

/// Manages the overlay window lifecycle and recommendation rendering.
class OverlayController {
    private var overlayWindow: OverlayWindow?
    private var fadeTimer: Timer?
    
    /// How long recommendations stay visible (seconds).
    var displayDuration: TimeInterval = 5.0
    
    func show() {
        DispatchQueue.main.async { [weak self] in
            let window = OverlayWindow()
            window.orderFrontRegardless()
            self?.overlayWindow = window
            print("[Overlay] Shown")
        }
    }
    
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.overlayWindow?.orderOut(nil)
            self?.overlayWindow = nil
            self?.fadeTimer?.invalidate()
            print("[Overlay] Hidden")
        }
    }
    
    /// Render new recommendations on the overlay.
    func render(recommendations: [Recommendation]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("[Overlay] Rendering \(recommendations.count) recommendations")
            print("[Overlay] Window exists: \(self.overlayWindow != nil)")
            print("[Overlay] Window visible: \(self.overlayWindow?.isVisible ?? false)")
            print("[Overlay] Window frame: \(self.overlayWindow?.frame ?? .zero)")
            
            if self.overlayWindow == nil {
                print("[Overlay] Window was nil, creating...")
                self.show()
            }
            
            self.overlayWindow?.updateRecommendations(recommendations)
            
            // Force window to front
            self.overlayWindow?.orderFrontRegardless()
            
            // Auto-fade after displayDuration
            self.fadeTimer?.invalidate()
            self.fadeTimer = Timer.scheduledTimer(withTimeInterval: self.displayDuration, repeats: false) { [weak self] _ in
                self?.overlayWindow?.clearRecommendations()
            }
        }
    }
}
