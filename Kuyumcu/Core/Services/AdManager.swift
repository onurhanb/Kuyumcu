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
    private enum LoadState {
        case idle
        case loading
        case ready
        case cooldown
    }

    static let shared = AdManager()

    @Published private(set) var isAdReady = false
    @Published private(set) var isLoading = false

    // Rewarded Ad Unit ID
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    private let adUnitID = "ca-app-pub-9919444685136366/2053652572"
    #endif

    private var rewardedAd: RewardedAd?
    private var rewardCompletion: (() -> Void)?
    private var retryTask: Task<Void, Never>?
    private var retryAttempt = 0
    private var loadState: LoadState = .idle
    private var loadedAt: Date?

    private let retrySchedule: [TimeInterval] = [5, 15, 45]
    private let adStaleAfter: TimeInterval = 60 * 50

    // MARK: - Init

    override private init() {
        super.init()
    }

    // MARK: - Load

    func loadAd(force: Bool = false) {
        guard ConsentInformation.shared.canRequestAds else {
            clearAdState()
            cancelScheduledRetry()
            return
        }

        if !force {
            switch loadState {
            case .loading, .cooldown:
                return
            case .ready:
                if let loadedAt, Date().timeIntervalSince(loadedAt) < adStaleAfter {
                    return
                }
            case .idle:
                break
            }
        }

        cancelScheduledRetry()
        loadState = .loading
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
                    self.handleLoadFailure(error)
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self as FullScreenContentDelegate
                self.loadedAt = Date()
                self.retryAttempt = 0
                self.loadState = .ready
                self.isAdReady = true
            }
        }
    }

    func handleAppDidBecomeActive() {
        guard ConsentInformation.shared.canRequestAds else { return }
        if let loadedAt, isAdReady, Date().timeIntervalSince(loadedAt) >= adStaleAfter {
            clearAdState()
        }
        loadAd()
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
            loadAd()
            return
        }

        loadState = .ready
        rewardCompletion = onRewarded
        ad.present(from: rootVC) { [weak self] in
            self?.rewardCompletion?()
            self?.rewardCompletion = nil
        }
    }

    private func handleLoadFailure(_ error: Error) {
        print("[AdManager] Yüklenemedi: \(error.localizedDescription)")
        clearAdState()
        scheduleRetry()
    }

    private func scheduleRetry() {
        guard ConsentInformation.shared.canRequestAds else { return }
        guard retryTask == nil else { return }

        loadState = .cooldown
        let delay = retrySchedule[min(retryAttempt, retrySchedule.count - 1)]
        retryAttempt += 1

        retryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await MainActor.run {
                guard let self else { return }
                self.retryTask = nil
                guard self.loadState == .cooldown else { return }
                self.loadState = .idle
                self.loadAd()
            }
        }
    }

    private func cancelScheduledRetry() {
        retryTask?.cancel()
        retryTask = nil
    }

    private func clearAdState() {
        rewardedAd = nil
        loadedAt = nil
        isAdReady = false
        isLoading = false
        if loadState != .cooldown {
            loadState = .idle
        }
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.clearAdState()
            self.loadAd(force: true)
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("[AdManager] Gösterilemedi: \(error.localizedDescription)")
            self.clearAdState()
            self.scheduleRetry()
        }
    }
}
