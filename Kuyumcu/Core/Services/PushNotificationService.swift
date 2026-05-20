import Combine
import Supabase
import UIKit
import UserNotifications

@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var dailyRateNotificationsEnabled: Bool

    private let savedTokenKey = "apnsDeviceToken"
    private let dailyRateNotificationsEnabledKey = "dailyRateNotificationsEnabled"
    private let environment: String = {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }()

    private override init() {
        dailyRateNotificationsEnabled = UserDefaults.standard.object(forKey: dailyRateNotificationsEnabledKey) as? Bool ?? true
        super.init()
    }

    func configureAndSync() async {
        guard dailyRateNotificationsEnabled else {
            await syncSavedTokenIfPossible()
            return
        }

        await refreshAuthorizationStatus()

        if authorizationStatus == .notDetermined {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                await refreshAuthorizationStatus()
                guard granted else { return }
            } catch {
                print("[Push] Bildirim izni alınamadı: \(error.localizedDescription)")
                return
            }
        }

        guard authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral else {
            return
        }

        UIApplication.shared.registerForRemoteNotifications()
        await syncSavedTokenIfPossible()
    }

    func updateDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: savedTokenKey)
        Task { await syncTokenIfPossible(token) }
    }

    func handleRegistrationError(_ error: Error) {
        print("[Push] APNs token alınamadı: \(error.localizedDescription)")
    }

    func syncSavedTokenIfPossible() async {
        guard let token = UserDefaults.standard.string(forKey: savedTokenKey), !token.isEmpty else { return }
        await syncTokenIfPossible(token)
    }

    func setDailyRateNotificationsEnabled(_ isEnabled: Bool) async {
        dailyRateNotificationsEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: dailyRateNotificationsEnabledKey)

        if isEnabled {
            await configureAndSync()
        } else {
            await syncSavedTokenIfPossible()
        }
    }

    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    private func syncTokenIfPossible(_ token: String) async {
        guard let accessToken = AuthService.shared.session?.accessToken else { return }

        do {
            supabase.functions.setAuth(token: accessToken)
            let response: RegisterPushTokenResponse = try await supabase.functions.invoke(
                "register-push-token",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: RegisterPushTokenRequest(
                        token: token,
                        environment: environment,
                        isActive: dailyRateNotificationsEnabled
                    )
                )
            )

            if !response.success {
                print("[Push] Token kaydedilemedi: \(response.error ?? "Bilinmeyen hata")")
            }
        } catch {
            print("[Push] Token senkronizasyon hatası: \(error.localizedDescription)")
        }
    }
}

private struct RegisterPushTokenRequest: Encodable {
    let token: String
    let environment: String
    let isActive: Bool
    let platform = "ios"

    enum CodingKeys: String, CodingKey {
        case token
        case environment
        case isActive = "is_active"
        case platform
    }
}

private struct RegisterPushTokenResponse: Decodable {
    let success: Bool
    let error: String?
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.updateDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.handleRegistrationError(error)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
