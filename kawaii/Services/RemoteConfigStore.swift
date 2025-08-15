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
#if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        rc.configSettings = settings
#endif
        rc.fetchAndActivate { [weak self] status, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.bubuEnabled = rc.configValue(forKey: "bubucheck").boolValue
                let codesString = rc.configValue(forKey: "invitecode").stringValue ?? ""
                let codes = codesString
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                self.inviteCodes = Set(codes)
                self.isLoaded = true
            }
        }
    }
}
