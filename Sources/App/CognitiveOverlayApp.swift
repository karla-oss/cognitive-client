import SwiftUI

@main
struct CognitiveOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar only — no main window
        Settings {
            SettingsView()
        }
    }
}
