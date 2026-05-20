//
//  AdManager.swift
//  Kuyumcu — Gold Dealer Life
//
//  Rewarded Ad yönetimi (Google AdMob)
//  Debug build'lerde Google test reklamı, Release build'lerde canlı rewarded ad kullanılır.

import GoogleMobileAds
import Combine
import UIKit
import UserMessagingPlatform

@MainActor
class AdManager: NSObject, ObservableObject {

    static let shared = AdManager()

    @Published var isAdReady = false
    @Published var isLoading = false

    // Rewarded Ad Unit ID
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    private let adUnitID = "ca-app-pub-9919444685136366/2053652572"
    #endif

    private var rewardedAd: RewardedAd?
    private var rewardCompletion: (() -> Void)?

    // MARK: - Init

    override private init() {
        super.init()
    }

    // MARK: - Load

    func loadAd() {
        guard ConsentInformation.shared.canRequestAds else {
            isAdReady = false
            return
        }
        guard !isLoading else { return }
        isLoading = true
        isAdReady = false

        RewardedAd.load(
            with: adUnitID,
            request: Request()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    print("[AdManager] Yüklenemedi: \(error.localizedDescription)")
                    self.rewardedAd = nil
                    self.isAdReady  = false
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self as FullScreenContentDelegate
                self.isAdReady = true
            }
        }
    }

    // MARK: - Show

    /// Reklamı göster. İzleme tamamlanınca `onRewarded` çağrılır.
    func showAd(onRewarded: @escaping () -> Void) {
        guard let ad = rewardedAd,
              let rootVC = UIApplication.shared
                  .connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first?.windows.first?.rootViewController
        else {
            // Reklam hazır değilse yeniden yükle, kullanıcıyı bildir
            loadAd()
            return
        }
        rewardCompletion = onRewarded
        ad.present(from: rootVC) { [weak self] in
            // Kullanıcı ödül kazandı
            self?.rewardCompletion?()
            self?.rewardCompletion = nil
        }
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.rewardedAd = nil
            self.isAdReady  = false
            self.loadAd()   // Sonraki gösterim için hazırla
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("[AdManager] Gösterilemedi: \(error.localizedDescription)")
            self.rewardedAd = nil
            self.isAdReady  = false
            self.loadAd()
        }
    }
}
