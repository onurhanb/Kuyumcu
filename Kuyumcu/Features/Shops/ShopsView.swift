import SwiftUI

struct ShopsView: View {
    @EnvironmentObject var gameState: GameState
    @State private var confirmBuy:  Shop? = nil
    @State private var confirmHire: Shop? = nil

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Owned shops
                    if !gameState.ownedShops.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sahip Olduklarım")
                                .font(.gdlHeadline())
                                .foregroundColor(.gdlGold)
                                .padding(.horizontal)

                            ForEach(gameState.ownedShops) { shop in
                                ShopCard(shop: shop, playerCash: gameState.playerCash, onHire: {
                                        confirmHire = shop
                                    })
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Locked shops
                    if !gameState.lockedShops.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Satın Alınabilir")
                                .font(.gdlHeadline())
                                .foregroundColor(.gdlTextSecondary)
                                .padding(.horizontal)

                            ForEach(gameState.lockedShops) { shop in
                                ShopCard(shop: shop, playerCash: gameState.playerCash, onBuy: {
                                    confirmBuy = shop
                                })
                                .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
        }
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
                    gameState.hireEmployee(shopId: shop.id)
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
    NavigationStack { ShopsView().environmentObject(GameState()) }
}
