import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var sessionController: SessionController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        sessionController = SessionController()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Cognitive Overlay")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Session", action: #selector(startSession), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Stop Session", action: #selector(stopSession), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func startSession() {
        sessionController?.start()
    }
    
    @objc private func stopSession() {
        sessionController?.stop()
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quit() {
        sessionController?.stop()
        NSApp.terminate(nil)
    }
}
