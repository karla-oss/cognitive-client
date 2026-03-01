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
            
            self.overlayWindow?.updateRecommendations(recommendations)
            
            // Auto-fade after displayDuration
            self.fadeTimer?.invalidate()
            self.fadeTimer = Timer.scheduledTimer(withTimeInterval: self.displayDuration, repeats: false) { [weak self] _ in
                self?.overlayWindow?.clearRecommendations()
            }
        }
    }
}
