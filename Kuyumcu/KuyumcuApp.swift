//
//  KuyumcuApp.swift
//  Kuyumcu — Gold Dealer Life
//

import SwiftUI
import GoogleMobileAds

@main
struct KuyumcuApp: App {
    @StateObject private var gameState      = GameState()
    @StateObject private var authService    = AuthService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var audioManager   = AudioManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        MobileAds.shared.start()
    }

    // Yeni kullanıcı → dükkan adı kurulumu
    @State private var needsShopSetup    = false
    // Supabase verisi yüklenirken splash
    @State private var isLoadingGameData = false
    // Supabase verileri bu oturum için zaten yüklendi mi?
    @State private var hasLoadedGameData = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !authService.isReady {
                    // Kayıtlı oturum kontrol edilirken splash göster
                    loadingView

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
                        gameState.shopName = name
                        Task { await SupabaseSaveService.save(gameState) }
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
            .onChange(of: scenePhase) { _, phase in
                // Ön plana dönerken arka planda biriken geliri hesapla
                if phase == .active {
                    gameState.applyOfflineTicks()
                }
            }
            .onChange(of: authService.session) { _, newSession in
                if newSession != nil && !hasLoadedGameData {
                    // Taze giriş VEYA kayıtlı oturum geri yüklendi → veri çek
                    Task { await handlePostLogin() }
                } else if newSession == nil {
                    // Oturum kapandı → state sıfırla
                    needsShopSetup    = false
                    hasLoadedGameData = false
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

        // Önce yerel cache'i yükle
        await MainActor.run { GameSaveService.load(into: gameState) }

        // Supabase'den veri yükle (yerel cache'in üzerine yazar)
        await SupabaseSaveService.load(into: gameState)
        await SupabaseSaveService.loadRates(into: gameState)
        await SupabaseSaveService.loadEvents(into: gameState)

        await MainActor.run {
            // Gerçek shop listesi yüklendikten sonra birikimi sıfırla ve timer'ı başlat
            gameState.shopAccumulatedIncome = [:]
            gameState.startPassiveTimer()
            isLoadingGameData = false
            // shopName hâlâ default "Misafir" ise yeni kullanıcı
            if gameState.shopName == "Misafir" {
                needsShopSetup = true
            }
        }
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
