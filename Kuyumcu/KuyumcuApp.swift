//
//  KuyumcuApp.swift
//  Kuyumcu — Gold Dealer Life
//

import SwiftUI

@main
struct KuyumcuApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var gameState      = GameState()
    @StateObject private var authService    = AuthService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var audioManager   = AudioManager.shared
    @StateObject private var consentManager = ConsentManager.shared
    @StateObject private var pushService    = PushNotificationService.shared
    @StateObject private var appUpdateService = AppUpdateService.shared

    // Yeni kullanıcı → dükkan adı kurulumu
    @State private var needsShopSetup    = false
    // Supabase verisi yüklenirken splash
    @State private var isLoadingGameData = false
    // Supabase verileri bu oturum için zaten yüklendi mi?
    @State private var hasLoadedGameData = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !appUpdateService.hasChecked || !authService.isReady {
                    // Kayıtlı oturum kontrol edilirken splash göster
                    loadingView

                } else if let requiredUpdate = appUpdateService.requiredUpdate {
                    ForcedUpdateView(config: requiredUpdate)

                } else if !networkMonitor.isConnected {
                    OfflineView()

                } else if authService.session == nil {
                    // Oturum yok → giriş ekranı
                    LoginView {
                        // onChange(of: session) handlePostLogin'i tetikleyecek
                    }

                } else if isLoadingGameData {
                    // Veri yüklenirken bekleme ekranı
                    loadingView

                } else if needsShopSetup {
                    // İlk kez giriş → dükkan adı al
                    ShopNameView { name in
                        gameState.shopName = GameState.normalizedShopName(name)
                        GameSaveService.save(gameState)
                        SupabaseSaveService.enqueueSave(gameState)
                        needsShopSetup = false
                    }

                } else {
                    // Ana oyun
                    MainTabView()
                        .environmentObject(gameState)
                        .environmentObject(audioManager)
                        .onAppear { audioManager.enterGeneralScreen() }
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await appUpdateService.refresh()
                await ServerClockService.shared.refresh()
                await consentManager.configureForAdsIfNeeded()
            }
            .onChange(of: authService.session) { _, newSession in
                if newSession != nil && !hasLoadedGameData {
                    // Taze giriş VEYA kayıtlı oturum geri yüklendi → veri çek
                    Task { await handlePostLogin() }
                } else if newSession == nil {
                    // Oturum kapandı → state sıfırla
                    gameState.resetLocalProgress()
                    needsShopSetup    = false
                    hasLoadedGameData = false
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        await appUpdateService.refresh()
                        await ServerClockService.shared.refresh()
                        await SupabaseSaveService.loadRates(into: gameState)
                        await SupabaseSaveService.loadEvents(into: gameState)
                        await pushService.syncSavedTokenIfPossible()
                        await MainActor.run {
                            AdManager.shared.handleAppDidBecomeActive()
                            refreshShopSetupRequirement()
                            guard !needsShopSetup else { return }
                            _ = gameState.syncProfitPeriodsIfNeeded(persistsChanges: true, syncsCloud: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Post Login Handler

    private func handlePostLogin() async {
        await MainActor.run {
            hasLoadedGameData = true   // çift çağrıyı önle
            isLoadingGameData = true
        }

        await ServerClockService.shared.refresh()

        // Önce yerel cache'i yükle. Oyun offline oynanmaz; bu sadece Supabase
        // geçici hata verirse mevcut oyuncuyu yanlışlıkla kurulum ekranına düşürmez.
        await MainActor.run { _ = GameSaveService.load(into: gameState) }

        // Supabase'den veri yükle (yerel cache'in üzerine yazar)
        await SupabaseSaveService.load(into: gameState)
        await SupabaseSaveService.loadRates(into: gameState)
        await SupabaseSaveService.loadEvents(into: gameState)
        await pushService.configureAndSync()
        await MainActor.run {
            gameState.syncEntryRightsIfNeeded()
            gameState.syncProfitPeriodsIfNeeded()
        }

        await MainActor.run {
            isLoadingGameData = false
            refreshShopSetupRequirement()
        }
    }

    @MainActor
    private func refreshShopSetupRequirement() {
        needsShopSetup = GameState.needsShopNameSetup(gameState.shopName)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.gdlGold)
                Text("Veriler yükleniyor...")
                    .font(.system(size: 14))
                    .foregroundColor(.gdlTextSecondary)
            }
        }
    }
}
