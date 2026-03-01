import Foundation
import ScreenCaptureKit
import CoreGraphics
import AppKit

/// Captured frame data ready for transmission.
struct CapturedFrame {
    let hash: String
    let imageBase64: String
    let width: Int
    let height: Int
    let timestamp: Date
}

/// Captures the active window using ScreenCaptureKit (macOS 14+).
class ScreenCaptureManager: NSObject {
    private var stream: SCStream?
    private var filter: SCContentFilter?
    private var isCapturing = false
    private let frameRate: Int
    private let maxWidth: Int
    private let maxHeight: Int
    
    /// Called with each captured frame
    var onFrame: ((CapturedFrame) -> Void)?
    
    init(frameRate: Int = 8, maxWidth: Int = 1280, maxHeight: Int = 720) {
        self.frameRate = frameRate
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        super.init()
    }
    
    func start() {
        guard !isCapturing else { return }
        
        Task {
            do {
                // Get available content
                let content = try await SCShareableContent.current
                
                // Find the frontmost window
                guard let window = content.windows
                    .filter({ $0.isOnScreen && $0.frame.width > 100 })
                    .sorted(by: { $0.windowLayer < $1.windowLayer })
                    .first else {
                    print("[Capture] No suitable window found")
                    return
                }
                
                print("[Capture] Capturing window: \(window.title ?? "untitled") (\(window.owningApplication?.applicationName ?? "unknown"))")
                
                // Create filter for this window
                let filter = SCContentFilter(desktopIndependentWindow: window)
                self.filter = filter
                
                // Configure stream
                let config = SCStreamConfiguration()
                config.width = min(Int(window.frame.width), maxWidth)
                config.height = min(Int(window.frame.height), maxHeight)
                config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(frameRate))
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.showsCursor = false
                
                // Create and start stream
                let stream = SCStream(filter: filter, configuration: config, delegate: self)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
                try await stream.startCapture()
                
                self.stream = stream
                self.isCapturing = true
                print("[Capture] Started at \(frameRate) FPS, \(config.width)x\(config.height)")
                
            } catch {
                print("[Capture] Error: \(error)")
            }
        }
    }
    
    func stop() {
        guard isCapturing else { return }
        
        Task {
            try? await stream?.stopCapture()
            stream = nil
            isCapturing = false
            print("[Capture] Stopped")
        }
    }
}

// MARK: - SCStreamOutput

extension ScreenCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        // Convert to JPEG base64
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else { return }
        
        let base64 = jpegData.base64EncodedString()
        let hash = String(base64.hashValue, radix: 16)
        
        let frame = CapturedFrame(
            hash: hash,
            imageBase64: base64,
            width: cgImage.width,
            height: cgImage.height,
            timestamp: Date()
        )
        
        onFrame?(frame)
    }
}

// MARK: - SCStreamDelegate

extension ScreenCaptureManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("[Capture] Stream stopped with error: \(error)")
        isCapturing = false
    }
}
