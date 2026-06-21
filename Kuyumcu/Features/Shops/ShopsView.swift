import SwiftUI

struct ShopsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    @State private var confirmBuy:  Shop? = nil
    @State private var confirmHire: Shop? = nil

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Owned shops
                    if !gameState.ownedShops.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeaderRow(
                                title: "Sahip Olduklarım",
                                detail: "\(gameState.ownedShops.count) dükkan",
                                color: .gdlGold
                            )

                            ForEach(gameState.ownedShops) { shop in
                                ShopCard(shop: shop, playerCash: gameState.playerCash, onHire: {
                                        audioManager.playEffect(.buttonTap)
                                        confirmHire = shop
                                    })
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Locked shops
                    if !gameState.lockedShops.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeaderRow(
                                title: "Satın Alınabilir",
                                detail: "\(gameState.lockedShops.count) seçenek"
                            )

                            ForEach(gameState.lockedShops) { shop in
                                ShopCard(shop: shop, playerCash: gameState.playerCash, onBuy: {
                                    audioManager.playEffect(.buttonTap)
                                    confirmBuy = shop
                                })
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 12)
            }
        }
        .gdlScreenBackground()
        .navigationTitle("Dükkanlar")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Dükkan Satın Al",
            isPresented: Binding(
                get: { confirmBuy != nil },
                set: { if !$0 { confirmBuy = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let shop = confirmBuy {
                Button("\(shop.name) — \(FormatUtils.tl(shop.purchasePrice))") {
                    if gameState.playerCash >= shop.purchasePrice {
                        audioManager.playEffect(.purchase)
                    }
                    gameState.buyShop(shop)
                    confirmBuy = nil
                }
                Button("İptal", role: .cancel) { confirmBuy = nil }
            }
        } message: {
            if let shop = confirmBuy {
                Text("Bu dükkanı \(FormatUtils.tl(shop.purchasePrice)) TL'ye satın almak istiyor musunuz?\nMevcut nakit: \(FormatUtils.tl(gameState.playerCash))")
            }
        }
        .alert(
            "Personel İşe Al",
            isPresented: Binding(
                get: { confirmHire != nil },
                set: { if !$0 { confirmHire = nil } }
            )
        ) {
            Button("Evet") {
                if let shop = confirmHire {
                    if gameState.playerCash >= shop.locationType.employeeHireCost {
                        audioManager.playEffect(.purchase)
                    }
                    gameState.hireEmployee(shopName: shop.name)
                }
                confirmHire = nil
            }
            .disabled(confirmHire.map { gameState.playerCash < $0.locationType.employeeHireCost } ?? true)
            Button("Hayır", role: .cancel) { confirmHire = nil }
        } message: {
            if let shop = confirmHire {
                let cost = shop.locationType.employeeHireCost
                if gameState.playerCash >= cost {
                    Text("\(shop.name) için personel ücreti \(FormatUtils.tl(cost)).\nMevcut nakit: \(FormatUtils.tl(gameState.playerCash))\n\nPersonel işe almak istiyor musunuz?")
                } else {
                    Text("\(shop.name) için personel ücreti \(FormatUtils.tl(cost)).\nMevcut nakit: \(FormatUtils.tl(gameState.playerCash))\n\nPersonel almak için yeterli nakit yok.")
                }
            }
        }
    }

}

#Preview {
    NavigationStack {
        ShopsView()
            .environmentObject(GameState())
            .environmentObject(AudioManager.shared)
    }
}
