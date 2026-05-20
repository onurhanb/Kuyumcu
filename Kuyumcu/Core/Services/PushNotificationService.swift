import Combine
import Supabase
import UIKit
import UserNotifications

@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let savedTokenKey = "apnsDeviceToken"
    private let environment: String = {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }()

    private override init() {
        super.init()
    }

    func configureAndSync() async {
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
                    body: RegisterPushTokenRequest(token: token, environment: environment)
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
    let platform = "ios"
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
