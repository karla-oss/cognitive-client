# Cognitive Overlay — macOS Client

Swift macOS menu bar app that captures the active window, streams frames to the signal server, and renders overlay recommendations.

## Requirements

- macOS 14+ (Sonoma)
- Xcode 15+
- Screen Recording permission

## Build

```bash
swift build
# or open Package.swift in Xcode
```

## Architecture

```
Sources/
├── App/           — App lifecycle, menu bar, session controller
├── Models/        — Codable contracts (matches server API)
├── Network/       — SessionManager, WebSocketClient, WebRTCClient
├── Capture/       — ScreenCaptureKit integration
├── Overlay/       — Transparent overlay window + renderer
└── Metadata/      — Cursor, click, focus tracking
```

## Flow

1. User clicks "Start Session" in menu bar
2. `SessionController` creates session via REST API
3. WebSocket connects for bidirectional messaging
4. ScreenCaptureKit captures active window at 5-8 FPS
5. Frames stream to server via WebRTC (or HTTP fallback)
6. Server sends recommendations back via WebSocket
7. Overlay renders recommendations on transparent NSWindow
8. Auto-fade after 5 seconds

## Configuration

Settings available via menu bar → Settings:
- **API URL** — signal server address (default: http://localhost:8090)
- **User ID** — your user UUID
