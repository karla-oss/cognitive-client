import Cocoa

/// Custom NSView that draws recommendation overlays.
class OverlayView: NSView {
    var recommendations: [Recommendation] = []
    
    override func draw(_ dirtyRect: NSRect) {
        // Clear background
        NSColor.clear.set()
        dirtyRect.fill()
        
        guard !recommendations.isEmpty else { return }
        
        let bounds = self.bounds
        
        for rec in recommendations {
            // Convert normalized coordinates to view coordinates
            // Note: macOS coordinate system is bottom-left origin
            let rect = NSRect(
                x: rec.x * bounds.width,
                y: (1.0 - rec.y - rec.height) * bounds.height, // flip Y
                width: rec.width * bounds.width,
                height: rec.height * bounds.height
            )
            
            drawRecommendation(rec, in: rect)
        }
    }
    
    private func drawRecommendation(_ rec: Recommendation, in rect: NSRect) {
        let color = colorForType(rec.type)
        let alpha: CGFloat = CGFloat(rec.confidence) * 0.6
        
        // Draw border highlight
        let borderPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        color.withAlphaComponent(alpha).setStroke()
        borderPath.lineWidth = 2.0
        borderPath.stroke()
        
        // Draw subtle fill
        color.withAlphaComponent(alpha * 0.15).setFill()
        borderPath.fill()
        
        // Draw label
        let labelRect = NSRect(
            x: rect.origin.x,
            y: rect.origin.y + rect.height + 2,
            width: rect.width,
            height: 18
        )
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: color.withAlphaComponent(0.9),
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        
        let label = " \(rec.text) "
        label.draw(in: labelRect, withAttributes: attrs)
        
        // Priority badge (top-right corner)
        if rec.priority <= 3 {
            let badgeRect = NSRect(
                x: rect.maxX - 16,
                y: rect.maxY - 16,
                width: 16,
                height: 16
            )
            let badgePath = NSBezierPath(ovalIn: badgeRect)
            color.withAlphaComponent(0.8).setFill()
            badgePath.fill()
            
            let priorityAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            "\(rec.priority)".draw(in: badgeRect.offsetBy(dx: 4, dy: 1), withAttributes: priorityAttrs)
        }
    }
    
    private func colorForType(_ type: RecommendationType) -> NSColor {
        switch type {
        case .action:  return NSColor.systemGreen
        case .info:    return NSColor.systemBlue
        case .warning: return NSColor.systemOrange
        case .hint:    return NSColor.systemPurple
        }
    }
}
