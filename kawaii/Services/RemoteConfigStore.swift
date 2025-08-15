import Foundation
import FirebaseRemoteConfig

@MainActor
final class RemoteConfigStore: ObservableObject {
    static let shared = RemoteConfigStore()

    @Published var isLoaded: Bool = false
    @Published var bubuEnabled: Bool = false
    @Published var inviteCodes: Set<String> = []

    private init() {}

    func refresh() {
        let rc = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        rc.configSettings = settings
        rc.fetchAndActivate { [weak self] status, error in
            let statusName = status == .successFetchedFromRemote ? "SUCCESS_FETCHED" : 
                           status == .successUsingPreFetchedData ? "SUCCESS_CACHED" : "ERROR"
            print("🔥 Firebase Remote Config result: \(statusName)")
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.bubuEnabled = rc.configValue(forKey: "bubucheck").boolValue
                let codesString = rc.configValue(forKey: "invitecode").stringValue ?? ""
                print("🔥 Remote Config values - bubuEnabled: \(self.bubuEnabled), inviteCodes: '\(codesString)'")
                let codes = codesString
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                self.inviteCodes = Set(codes)
                self.isLoaded = true
            }
        }
    }
}
