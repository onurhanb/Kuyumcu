import SwiftUI

struct LifestyleView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    @State private var selectedCategory: LifestyleCategory = .daily
    @State private var purchasedItem: LifestyleItem? = nil
    @State private var showCongrats = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Kategori seçici
                categoryPicker

                // Ürün listesi
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(itemsForCategory) { item in
                            LifestyleItemCard(item: item) {
                                audioManager.playEffect(.purchase)
                                gameState.buyLifestyleItem(item)
                                purchasedItem = item
                                showCongrats  = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 80)
                    .animation(.none, value: selectedCategory)
                }
                .id(selectedCategory)
            }
        }
        .gdlScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Yaşam Tarzı")
        .alert("Hayırlı Olsun! 🎉", isPresented: $showCongrats) {
            Button("Teşekkürler", role: .cancel) {}
        } message: {
            if let item = purchasedItem {
                Text("\(item.name) satın aldın! +\(item.lifestylePoints) yaşam puanı kazandın.")
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LifestyleCategory.allCases, id: \.self) { cat in
                    Button {
                        audioManager.playEffect(.buttonTap)
                        selectedCategory = cat
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: cat.icon)
                                .font(.caption)
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedCategory == cat ? .black : .gdlTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedCategory == cat ? Color.gdlGold : Color.gdlCard)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.18), value: selectedCategory)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
    }

    // MARK: - Filtered Items

    private var itemsForCategory: [LifestyleItem] {
        gameState.lifestyleItems.filter { $0.category == selectedCategory }
    }
}

// MARK: - Item Card

struct LifestyleItemCard: View {
    let item: LifestyleItem
    let onBuy: () -> Void

    @EnvironmentObject var gameState: GameState

    private var canAfford: Bool { gameState.playerCash >= item.price }

    var body: some View {
        HStack(spacing: 14) {
            // İkon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.isOwned ? Color.gdlGold.opacity(0.2) : Color.gdlCardSecondary)
                    .frame(width: 52, height: 52)
                let imgKey = lifestyleImageKey(item.name)
                if UIImage(named: imgKey) != nil {
                    Image(imgKey)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(item.isOwned ? 0.6 : 1.0)
                } else {
                    Image(systemName: item.icon)
                        .font(.system(size: 22))
                        .foregroundColor(item.isOwned ? .gdlGold : .gdlTextSecondary)
                }
            }

            // Ad + fiyat
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.gdlBody())
                    .foregroundColor(item.isOwned ? .gdlTextSecondary : .gdlTextPrimary)
                HStack(spacing: 8) {
                    Text(FormatUtils.tl(item.price))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(item.isOwned ? .gdlTextSecondary : (canAfford ? .gdlTextPrimary : .gdlNegative))
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gdlGold)
                        Text("+\(item.lifestylePoints)")
                            .font(.system(size: 12))
                            .foregroundColor(.gdlGold)
                    }
                }
            }

            Spacer()

            // Satın al / Alındı butonu
            if item.isOwned {
                StatusBadge(title: "Alındı", icon: "checkmark.circle.fill", color: .gdlPositive)
            } else {
                CompactActionButton(title: "Satın Al", style: .gold, isDisabled: !canAfford) {
                    onBuy()
                }
                .disabled(!canAfford)
            }
        }
        .padding(14)
        .gdlCard()
        .opacity(item.isOwned ? 0.7 : 1.0)
    }

    private func lifestyleImageKey(_ name: String) -> String {
        let slug = name
            .replacingOccurrences(of: "İ", with: "i")
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "+", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        return "lifestyle_\(slug)"
    }
}

#Preview {
    NavigationStack {
        LifestyleView()
    }
    .environmentObject(GameState())
    .environmentObject(AudioManager.shared)
}
