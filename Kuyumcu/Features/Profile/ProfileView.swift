import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    // 1. Profil kartı
                    profileCard
                        .padding(.horizontal)

                    // 2. Finansal Durum (grid + servet grafiği)
                    financialCard
                        .padding(.horizontal)

                    // 3. Yaşam Tarzı (öne alındı)
                    lifestyleCard
                        .padding(.horizontal)

                    // 4. İstatistikler
                    statsCard
                        .padding(.horizontal)

                    // 5. Envanter (ikonlu)
                    inventoryCard
                        .padding(.horizontal)

                    // Ayarlar
                    SectionCard(title: "Ayarlar", icon: "gearshape.fill") {
                        settingRow("Ses Efektleri", value: "Açık")
                        settingRow("Müzik", value: "Açık")
                        settingRow("Bildirimler", value: "Kapalı")
                        settingRow("Uygulama Versiyonu", value: "1.0.0 Alpha")
                    }
                    .padding(.horizontal)

                    // Oyunu Sıfırla butonu
                    Button {
                        showResetAlert = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 18))
                            Text("Oyunu Sıfırla")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gdlNegative)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .alert("Oyunu Sıfırla", isPresented: $showResetAlert) {
            Button("Sıfırla", role: .destructive) {
                gameState.resetGame()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Tüm ilerleme silinecek ve oyun baştan başlayacak. Bu işlem geri alınamaz.")
        }
    }

    // MARK: - 1. Profil Kartı

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gdlGold.opacity(0.18))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.gdlGold)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(gameState.shopName)
                    .font(.gdlTitle())
                    .foregroundColor(.gdlTextPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlGold)
                    Text("Net Servet: \(FormatUtils.tl(gameState.totalNetWorth))")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .gdlCard()
    }

    // MARK: - 2. Finansal Durum

    private var financialCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Başlık
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill").foregroundColor(.gdlGold).font(.subheadline)
                Text("Finansal Durum").font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().background(Color.gdlDivider).padding(.horizontal, 14)

            // 3×2 grid
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    finCell(label: "Toplam Servet",  value: FormatUtils.tl(gameState.totalNetWorth), color: .gdlGold, trailing: true)
                    finCell(label: "Nakit",          value: FormatUtils.tl(gameState.playerCash),    color: .gdlTextPrimary, trailing: false)
                }
                Divider().background(Color.gdlDivider).padding(.horizontal, 14)
                HStack(spacing: 0) {
                    finCell(label: "Toplam Kâr",     value: FormatUtils.tl(gameState.totalProfit),   color: .gdlPositive, trailing: true)
                    finCell(label: "Günlük Kâr",     value: FormatUtils.tl(gameState.dailyProfit),   color: gameState.dailyProfit >= 0 ? .gdlPositive : .gdlNegative, trailing: false)
                }
                Divider().background(Color.gdlDivider).padding(.horizontal, 14)
                HStack(spacing: 0) {
                    finCell(label: "Haftalık Kâr",   value: FormatUtils.tl(gameState.weeklyProfit),  color: .gdlTextPrimary, trailing: true)
                    finCell(label: "Aylık Ciro",     value: FormatUtils.tl(gameState.monthlyRevenue),color: .gdlTextPrimary, trailing: false)
                }
            }

            Divider().background(Color.gdlDivider).padding(.horizontal, 14)

            // Servet dağılım grafiği
            wealthBreakdownChart
                .padding(14)
        }
        .background(Color.gdlCard)
        .cornerRadius(16)
    }

    private func finCell(label: String, value: String, color: Color, trailing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.gdlCaption())
                .foregroundColor(.gdlTextSecondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(alignment: .trailing) {
            if trailing {
                Rectangle().frame(width: 1).foregroundColor(Color.gdlDivider)
            }
        }
    }

    // Servet dağılım çubuğu
    private var wealthBreakdownChart: some View {
        let inv = gameState.inventory
        let rates = gameState.rates

        func midPrice(_ type: String) -> Double {
            guard let r = rates.first(where: { $0.type == type }) else { return 0 }
            return (r.buyPrice + r.sellPrice) / 2
        }

        let gramVal    = inv.gramGold    * midPrice("gramGold")
        let qVal       = inv.quarterGold * midPrice("quarterGold")
        let hVal       = inv.halfGold    * midPrice("halfGold")
        let fVal       = inv.fullGold    * midPrice("fullGold")
        let usdVal     = inv.usd         * midPrice("USD")
        let eurVal     = inv.eur         * midPrice("EUR")
        let cashVal    = gameState.playerCash

        let segments: [(label: String, value: Double, color: Color)] = [
            ("Nakit",         cashVal, Color(red: 0.45, green: 0.85, blue: 0.55)),   // açık yeşil
            ("Gram Altın",    gramVal, Color(red: 0.80, green: 0.35, blue: 0.05)),   // koyu turuncu
            ("Çeyrek",        qVal,    Color(red: 0.95, green: 0.60, blue: 0.20)),   // açık turuncu
            ("Yarım",         hVal,    Color(red: 0.75, green: 0.65, blue: 0.00)),   // koyu sarı
            ("Tam Altın",     fVal,    Color(red: 0.98, green: 0.90, blue: 0.30)),   // açık sarı
            ("USD",           usdVal,  Color(red: 0.15, green: 0.70, blue: 0.30)),   // yeşil
            ("EUR",           eurVal,  Color(red: 0.20, green: 0.45, blue: 0.90)),   // mavi
        ].filter { $0.value > 0 }

        let total = segments.reduce(0) { $0 + $1.value }
        guard total > 0 else {
            return AnyView(
                Text("Veri yok")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            )
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Servet Dağılımı")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)

                // Yatay bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(segments, id: \.label) { seg in
                            let w = (seg.value / total) * geo.size.width
                            Rectangle()
                                .fill(seg.color)
                                .frame(width: max(w - 2, 0))
                                .cornerRadius(3)
                        }
                    }
                }
                .frame(height: 16)

                // Lejant
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(segments, id: \.label) { seg in
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(seg.color)
                                .frame(width: 10, height: 10)
                            Text(seg.label)
                                .font(.system(size: 11))
                                .foregroundColor(.gdlTextSecondary)
                            Spacer()
                            Text("%\(Int((seg.value / total) * 100))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gdlTextPrimary)
                        }
                    }
                }
            }
        )
    }

    // MARK: - 3. Yaşam Tarzı (öne alındı)

    private var lifestyleCard: some View {
        SectionCard(title: "Yaşam Tarzı", icon: "star.fill") {
            // Özet
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Yaşam Puanı")
                        .font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                    Text("\(gameState.lifestyleScore) puan")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.gdlGold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Sahip olunan")
                        .font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                    Text("\(gameState.lifestyleItems.filter { $0.isOwned }.count) / \(gameState.lifestyleItems.count)")
                        .font(.gdlBody()).foregroundColor(.gdlTextPrimary)
                }
            }

            Divider().background(Color.gdlDivider).padding(.vertical, 4)

            // Her kategori için grid
            ForEach(LifestyleCategory.allCases, id: \.self) { cat in
                let allInCat   = gameState.lifestyleItems.filter { $0.category == cat }
                let ownedInCat = allInCat.filter { $0.isOwned }

                VStack(alignment: .leading, spacing: 8) {
                    // Kategori başlığı
                    HStack(spacing: 6) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.gdlGold)
                        Text(cat.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gdlTextPrimary)
                        Spacer()
                        Text("\(ownedInCat.count)/\(allInCat.count)")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                    }

                    if ownedInCat.isEmpty {
                        Text("Henüz satın alınmadı")
                            .font(.system(size: 11))
                            .foregroundColor(.gdlTextSecondary)
                            .padding(.vertical, 4)
                    } else {
                        // 6 sütunlu grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                            spacing: 6
                        ) {
                            ForEach(ownedInCat) { item in
                                lifestyleThumb(item: item)
                            }
                        }
                    }
                }

                if cat != LifestyleCategory.allCases.last {
                    Divider().background(Color.gdlDivider).padding(.vertical, 2)
                }
            }
        }
    }

    private func lifestyleThumb(item: LifestyleItem) -> some View {
        let imgKey = lifestyleImageKey(item.name)
        let hasImage = UIImage(named: imgKey) != nil

        return VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gdlCardSecondary)
                    .aspectRatio(1, contentMode: .fit)

                if hasImage {
                    Image(imgKey)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.gdlGold)
                }
            }

            Text(item.name)
                .font(.system(size: 8))
                .foregroundColor(.gdlTextSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    /// "Espresso Makinesi" → "lifestyle_espresso_makinesi"
    private func lifestyleImageKey(_ name: String) -> String {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        return "lifestyle_\(slug)"
    }

    // MARK: - 4. İşlem İstatistikleri

    private var statsCard: some View {
        SectionCard(title: "İşlem İstatistikleri", icon: "list.bullet.clipboard") {
            statRow("Toplam İşlem",        "\(gameState.totalTransactions)")
            statRow("Kabul Edilen",        "\(gameState.acceptedDeals)")
            statRow("Reddedilen",          "\(gameState.rejectedDeals)")
            statRow("Müşteri Memnuniyeti", "\(gameState.customerSatisfaction)/100")
            statRow("Güven Puanı",         String(format: "%.1f/100", gameState.trustScore))
            if gameState.totalTransactions > 0 {
                let rate = Int(Double(gameState.acceptedDeals) / Double(gameState.totalTransactions) * 100)
                statRow("Kabul Oranı", "%\(rate)")
            }
        }
    }

    // MARK: - 5. Envanter (ikonlu)

    private var inventoryCard: some View {
        SectionCard(title: "Envanter", icon: "archivebox.fill") {
            inventoryRow(icon: "circle.fill",             color: Color(red: 0.80, green: 0.35, blue: 0.05), label: "Gram Altın",   value: FormatUtils.decimal(gameState.inventory.gramGold) + " gr")
            inventoryRow(icon: "circle.lefthalf.filled",  color: Color(red: 0.95, green: 0.60, blue: 0.20), label: "Çeyrek Altın", value: FormatUtils.decimal(gameState.inventory.quarterGold) + " adet")
            inventoryRow(icon: "circle.bottomhalf.filled",color: Color(red: 0.75, green: 0.65, blue: 0.00), label: "Yarım Altın",  value: FormatUtils.decimal(gameState.inventory.halfGold) + " adet")
            inventoryRow(icon: "seal.fill",               color: Color(red: 0.98, green: 0.90, blue: 0.30), label: "Tam Altın",    value: FormatUtils.decimal(gameState.inventory.fullGold) + " adet")
            inventoryRow(icon: "dollarsign.circle.fill",  color: Color(red: 0.15, green: 0.70, blue: 0.30), label: "USD",          value: FormatUtils.decimal(gameState.inventory.usd) + " $")
            inventoryRow(icon: "eurosign.circle.fill",    color: Color(red: 0.20, green: 0.45, blue: 0.90), label: "EUR",          value: FormatUtils.decimal(gameState.inventory.eur) + " €")
        }
    }

    // MARK: - Yardımcılar

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.gdlBody()).foregroundColor(.gdlTextSecondary)
            Spacer()
            Text(value).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
        }
        .padding(.vertical, 3)
    }

    private func inventoryRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)
            Text(label).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
            Spacer()
            Text(value).font(.gdlBody()).foregroundColor(.gdlTextSecondary)
        }
        .padding(.vertical, 3)
    }

    private func settingRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
            Spacer()
            Text(value).font(.gdlBody()).foregroundColor(.gdlTextSecondary)
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gdlDivider)
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    NavigationStack { ProfileView().environmentObject(GameState()) }
}
