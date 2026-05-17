//
//  KuyumcuApp.swift
//  Kuyumcu — Gold Dealer Life
//

import SwiftUI

@main
struct KuyumcuApp: App {
    @StateObject private var gameState      = GameState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var isLoggedIn           = false
    @State private var showShopName         = false

    var body: some Scene {
        WindowGroup {
            if !networkMonitor.isConnected {
                OfflineView()
                    .preferredColorScheme(.dark)
            } else if isLoggedIn {
                MainTabView()
                    .environmentObject(gameState)
                    .preferredColorScheme(.dark)
            } else if showShopName {
                ShopNameView { name in
                    gameState.shopName = name
                    gameState.isGuest  = false
                    GameSaveService.save(gameState)
                    isLoggedIn = true
                }
                .preferredColorScheme(.dark)
            } else {
                LoginView(
                    onAuthLogin: {
                        showShopName = true
                    },
                    onGuestLogin: {
                        gameState.shopName = "Misafir"
                        gameState.isGuest  = true
                        GameSaveService.save(gameState)
                        isLoggedIn = true
                    }
                )
                .preferredColorScheme(.dark)
            }
        }
    }
}
