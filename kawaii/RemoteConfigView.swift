import SwiftUI
import FirebaseRemoteConfig

struct RemoteConfigView: View {
    @State private var isLoading: Bool = true
    @State private var configText: String = ""
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("Fetching Remote Config…")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ScrollView {
                    Text(configText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .onAppear {
            fetchConfig()
        }
    }
    
    private func fetchConfig() {
#if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // always fetch during development
        remoteConfig.configSettings = settings
#endif
        
        remoteConfig.fetchAndActivate { status, error in
            DispatchQueue.main.async {
                defer { isLoading = false }
                if let error = error {
                    configText = "Remote Config fetch failed: \(error.localizedDescription)"
                    return
                }
                
                let keys = remoteConfig.allKeys(from: .remote)
                if keys.isEmpty {
                    configText = "No remote config values found."
                } else {
                    configText = keys.sorted().map { key in
                        let value = remoteConfig.configValue(forKey: key).stringValue ?? "<nil>"
                        return "\(key): \(value)"
                    }.joined(separator: "\n")
                }
            }
        }
    }
}

#Preview {
    RemoteConfigView()
}
