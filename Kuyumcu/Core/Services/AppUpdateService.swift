import Foundation
import Combine
import Supabase

struct AppUpdateConfig: Decodable, Equatable {
    let minimumSupportedVersion: String
    let latestVersion: String
    let updateMessage: String
    let appStoreURL: String

    enum CodingKeys: String, CodingKey {
        case minimumSupportedVersion = "minimum_supported_version"
        case latestVersion = "latest_version"
        case updateMessage = "update_message"
        case appStoreURL = "app_store_url"
    }

    var requiresUpdate: Bool {
        AppVersion.isVersion(AppVersion.current.short, below: minimumSupportedVersion)
    }
}

@MainActor
final class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()

    @Published private(set) var config: AppUpdateConfig?
    @Published private(set) var hasChecked = false

    private init() {}

    var requiredUpdate: AppUpdateConfig? {
        guard let config, config.requiresUpdate else { return nil }
        return config
    }

    func refresh() async {
        defer { hasChecked = true }

        do {
            let fetchedConfig: AppUpdateConfig = try await supabase
                .from("app_config")
                .select("minimum_supported_version, latest_version, update_message, app_store_url")
                .eq("id", value: 1)
                .single()
                .execute()
                .value
            config = fetchedConfig
        } catch {
            print("[AppUpdate] config yüklenemedi:", error.localizedDescription)
        }
    }
}
