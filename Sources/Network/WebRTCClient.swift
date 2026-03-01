import Foundation
import AVFoundation

/// WebRTC client for streaming video frames to the signal server.
/// Uses HTTP signaling (POST /api/v1/webrtc/offer) per contract.
///
/// NOTE: This is a simplified implementation. For production, integrate
/// Google's WebRTC framework (GoogleWebRTC pod or WebRTC.xcframework).
/// This version uses HTTP frame posting as a fallback.
class WebRTCClient {
    private let signalingURL: String
    private let sessionID: String
    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var isConnected = false
    
    init(signalingURL: String, sessionID: String) {
        self.signalingURL = signalingURL
        self.sessionID = sessionID
    }
    
    /// Connect via SDP exchange.
    /// In production: create RTCPeerConnection, generate offer, exchange SDP.
    /// For MVP: we'll use HTTP frame posting until native WebRTC is integrated.
    func connect(completion: @escaping (Bool) -> Void) {
        print("[WebRTC] Connecting (session: \(sessionID))")
        
        // TODO: Integrate GoogleWebRTC framework
        // 1. Create RTCPeerConnection with STUN server
        // 2. Add video track from ScreenCaptureKit
        // 3. Create SDP offer
        // 4. POST offer to signalingURL
        // 5. Set remote SDP from answer
        // 6. Handle ICE candidates
        
        // For now, mark as connected — frames will be sent via HTTP fallback
        isConnected = true
        completion(true)
    }
    
    func disconnect() {
        isConnected = false
        print("[WebRTC] Disconnected")
    }
    
    /// Send a captured frame.
    /// Production: frame goes through RTCVideoSource → RTP → server.
    /// MVP fallback: HTTP POST base64 frame (higher latency but functional).
    func sendFrame(_ frame: CapturedFrame) {
        guard isConnected else { return }
        
        // MVP: HTTP frame posting fallback
        // Production: this would go through the WebRTC video track
        postFrameHTTP(frame)
    }
    
    // MARK: - HTTP Fallback (MVP)
    
    private func postFrameHTTP(_ frame: CapturedFrame) {
        guard let url = URL(string: signalingURL.replacingOccurrences(of: "/webrtc/offer", with: "/frames")) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        
        let payload: [String: Any] = [
            "frame_hash": frame.hash,
            "session_id": sessionID,
            "image_b64": frame.imageBase64,
            "width": frame.width,
            "height": frame.height,
            "timestamp": ISO8601DateFormatter().string(from: frame.timestamp)
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                print("[WebRTC] Frame send error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // MARK: - SDP Exchange (for production WebRTC)
    
    func exchangeSDP(offerSDP: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: signalingURL) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let signalingReq = SignalingRequest(type: "offer", sdp: offerSDP, sessionID: sessionID)
        request.httpBody = try? encoder.encode(signalingReq)
        
        session.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let self = self else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                let response = try self.decoder.decode(SignalingResponse.self, from: data)
                completion(.success(response.sdp))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
