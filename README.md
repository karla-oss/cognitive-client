# Cognitive Overlay — macOS Client

Swift macOS menu bar app that captures the active window, streams frames to the signal server, and renders overlay recommendations.

## Requirements

- macOS 14+ (Sonoma)
- Xcode 15+
- Apple Developer account (free is fine for local builds)

## Build & Run

### Option 1: Xcode (recommended)

```bash
open Package.swift
```

1. Xcode откроет проект автоматически
2. Выбери схему **CognitiveOverlay** и target **My Mac**
3. `Cmd + R` — build & run
4. В menu bar появится иконка 🧠

### Option 2: Command line

```bash
swift build
.build/debug/CognitiveOverlay
```

### Первый запуск

1. Приложение появится в **menu bar** (иконка мозга, правый верхний угол)
2. Нажми на иконку → **Settings...**
3. Укажи:
   - **API URL** — адрес signal сервера (например `http://31.220.79.2:8090` или `http://localhost:8090`)
   - **User ID** — твой UUID (или оставь автосгенерированный)
4. Закрой Settings

### Запуск сессии

1. Нажми на иконку 🧠 в menu bar
2. **Start Session** — начнётся захват экрана и стриминг
3. Overlay появится поверх всех окон (прозрачный, кликабельный сквозь)
4. Рекомендации будут отображаться цветными рамками:
   - 🟢 **action** — важные кнопки/действия
   - 🔵 **info** — информационные элементы
   - 🟠 **warning** — модалки, диалоги
   - 🟣 **hint** — подсказки (пустые поля и т.д.)

### Остановка сессии

1. Нажми на иконку 🧠 в menu bar
2. **Stop Session** — захват остановится, overlay исчезнет, сессия закроется на сервере

### Выход

Menu bar → **Quit** (или `Cmd + Q`)

Сессия автоматически остановится перед выходом.

## Permissions (обязательно!)

Приложению нужны два разрешения. Без них захват экрана не будет работать.

### 1. Screen Recording

macOS потребует разрешение при первом запуске. Если не спросил:

1. **System Settings** → **Privacy & Security** → **Screen Recording**
2. Нажми **+** (или разблокируй замок 🔒)
3. Добавь **CognitiveOverlay** (или Xcode, если запускаешь через него)
4. Включи тогл ✅
5. **Перезапусти приложение** — разрешение применяется только после перезапуска

> ⚠️ Если запускаешь через Xcode, нужно дать Screen Recording доступ именно **Xcode**, а не приложению. Для standalone build — самому приложению.

### 2. Accessibility (для отслеживания курсора и кликов)

1. **System Settings** → **Privacy & Security** → **Accessibility**
2. Нажми **+**
3. Добавь **CognitiveOverlay** (или Xcode)
4. Включи тогл ✅

### 3. Input Monitoring (опционально, для keypress событий)

1. **System Settings** → **Privacy & Security** → **Input Monitoring**
2. Добавь приложение и включи

### Как проверить что permissions работают

После выдачи разрешений:
1. Start Session
2. В консоли Xcode (или терминале) должно появиться:
   ```
   [Session] Starting...
   [Session] Created: <uuid>
   [WS] Connected
   [Capture] Capturing window: Safari (Safari)
   [Capture] Started at 8 FPS, 1280x720
   [Metadata] Tracking started
   ```
3. Если видишь `[Capture] No suitable window found` — Screen Recording не дан
4. Если metadata не приходят — Accessibility не дан

### Сброс permissions (если что-то пошло не так)

```bash
# Сбросить все разрешения Screen Recording
tccutil reset ScreenCapture

# Сбросить Accessibility
tccutil reset Accessibility
```

После сброса перезапусти приложение — macOS спросит разрешения заново.

## Architecture

```
Sources/
├── App/           — App lifecycle, menu bar, session controller
│   ├── CognitiveOverlayApp.swift   — @main entry point
│   ├── AppDelegate.swift           — Menu bar setup
│   ├── SessionController.swift     — Orchestrates all components
│   ├── ClientConfig.swift          — Configuration
│   └── SettingsView.swift          — Settings UI
│
├── Models/        — Codable contracts (matches server API exactly)
│   └── Contracts.swift             — All request/response structs
│
├── Network/       — Server communication
│   ├── SessionManager.swift        — REST: create/get/end session, feedback
│   ├── WebSocketClient.swift       — WS: metadata out, recommendations in
│   └── WebRTCClient.swift          — WebRTC signaling + HTTP fallback
│
├── Capture/       — Screen capture
│   └── ScreenCaptureManager.swift  — ScreenCaptureKit, JPEG encode, 8 FPS
│
├── Overlay/       — Visual overlay
│   ├── OverlayWindow.swift         — Transparent click-through NSWindow
│   ├── OverlayView.swift           — Draws recommendation highlights
│   └── OverlayController.swift     — Lifecycle + auto-fade
│
└── Metadata/      — User activity tracking
    └── MetadataTracker.swift       — Cursor, clicks, focus changes
```

## Flow

```
Start Session
    │
    ├─ POST /api/v1/sessions → получаем session ID, ws_url, rtc_url
    │
    ├─ WebSocket connect (ws_url)
    │   ├─ Client → Server: metadata (cursor, clicks, focus)
    │   └─ Server → Client: recommendations, status, errors
    │
    ├─ WebRTC connect (rtc_url) — SDP offer/answer exchange
    │   └─ ScreenCaptureKit → frames → WebRTC video track → server
    │
    ├─ OverlayWindow показывается поверх всех окон
    │   └─ Recommendations рендерятся как цветные рамки + текст
    │
    └─ MetadataTracker отправляет cursor/click/focus через WebSocket

Stop Session
    │
    ├─ Capture stops
    ├─ WebRTC disconnects
    ├─ WebSocket disconnects
    ├─ Overlay hides
    └─ POST /api/v1/sessions/{id}/end
```

## Troubleshooting

| Проблема | Решение |
|----------|---------|
| Нет иконки в menu bar | Проверь что приложение запущено, посмотри Console.app |
| Screen capture не работает | System Settings → Screen Recording → добавь app |
| Курсор не трекается | System Settings → Accessibility → добавь app |
| WS disconnect | Проверь что signal server запущен и API URL правильный |
| "No suitable window found" | Открой хотя бы одно окно перед Start Session |
| Overlay не показывается | Может быть за fullscreen окном — попробуй windowed mode |
