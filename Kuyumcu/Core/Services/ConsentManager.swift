import AppTrackingTransparency
import Combine
import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

@MainActor
final class ConsentManager: ObservableObject {
    static let shared = ConsentManager()

    @Published private(set) var isConfigured = false
    @Published private(set) var isPrivacyOptionsRequired = false

    private var isConfiguring = false
    private var hasStartedAds = false

    private init() {}

    func configureForAdsIfNeeded() async {
        guard !isConfiguring, !isConfigured else { return }
        isConfiguring = true
        defer { isConfiguring = false }

        do {
            try await requestConsentInfoUpdate()
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            await requestTrackingAuthorizationIfNeeded()
        } catch {
            print("[ConsentManager] Consent akışı tamamlanamadı: \(error.localizedDescription)")
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        }

        isConfigured = true
        startAdsIfAllowed()
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            startAdsIfAllowed()
        } catch {
            print("[ConsentManager] Gizlilik seçenekleri açılamadı: \(error.localizedDescription)")
        }
    }

    private func requestConsentInfoUpdate() async throws {
        let parameters = RequestParameters()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func requestTrackingAuthorizationIfNeeded() async {
        guard #available(iOS 14.5, *) else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        guard UIApplication.shared.applicationState == .active else { return }

        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    private func startAdsIfAllowed() {
        guard ConsentInformation.shared.canRequestAds else { return }
        guard !hasStartedAds else {
            AdManager.shared.loadAd()
            return
        }

        hasStartedAds = true
        MobileAds.shared.start()
        AdManager.shared.loadAd()
    }
}
