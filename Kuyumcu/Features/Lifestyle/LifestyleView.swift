import SwiftUI

struct LifestyleView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedCategory: LifestyleCategory = .daily
    @State private var purchasedItem: LifestyleItem? = nil
    @State private var showCongrats = false

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Başlık + Puan satırı
                HStack(alignment: .center) {
                    Text("Yaşam Tarzı")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.gdlGold)
                        Text("\(gameState.lifestyleScore)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.gdlGold)
                        Text("puan")
                            .font(.system(size: 12))
                            .foregroundColor(.gdlTextSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gdlCard)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 52)
                .padding(.bottom, 4)

                // Kategori seçici
                categoryPicker

                // Ürün listesi
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(itemsForCategory) { item in
                            LifestyleItemCard(item: item) {
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
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
                        .cornerRadius(20)
                        .animation(.easeInOut(duration: 0.18), value: selectedCategory)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
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
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gdlPositive)
                    Text("Alındı")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gdlPositive)
                }
            } else {
                Button {
                    onBuy()
                } label: {
                    Text("Satın Al")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(canAfford ? .black : .gdlTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(canAfford ? Color.gdlGold : Color.gdlCardSecondary)
                        .cornerRadius(8)
                }
                .disabled(!canAfford)
            }
        }
        .padding(14)
        .background(Color.gdlCard)
        .cornerRadius(14)
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
}
