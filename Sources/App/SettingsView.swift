import SwiftUI

struct SettingsView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL = "http://localhost:8090"
    @AppStorage("userID") private var userID = ""
    
    var body: some View {
        Form {
            Section("Server") {
                TextField("API URL", text: $apiBaseURL)
                    .textFieldStyle(.roundedBorder)
            }
            Section("User") {
                TextField("User ID", text: $userID)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
