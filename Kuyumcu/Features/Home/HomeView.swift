import SwiftUI

// MARK: - Info Tips (etkinlik yokken gösterilir)
private let infoTips: [(icon: String, text: String)] = [
    ("scalemass.fill",        "Müşterileri memnun tutmak için adil fiyat teklifleri yapın."),
    ("clock.badge.checkmark", "Pasif geliri her gün toplayarak nakit akışınızı artırın."),
    ("star.fill",             "Daha prestijli lokasyonlar daha fazla VIP müşteri getirir."),
    ("chart.line.uptrend.xyaxis", "Altın fiyatları döviz kurlarından doğrudan etkilenir."),
    ("person.2.fill",         "Personel yükseltmesi pasif gelir çarpanınızı artırır."),
    ("shield.fill",           "Güvenlik yükseltmesi dolandırıcılık riskini azaltır."),
]

struct HomeView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showCounter     = false
    @State private var showIncomeAlert = false
    @State private var tipIndex        = Int.random(in: 0..<infoTips.count)
    @State private var rankingTab      = 0

    // Kur ticker metni
    private var ratesTickerText: String {
        let labels: [String: String] = [
            "gramGold":    "Gram",
            "quarterGold": "Çeyrek",
            "halfGold":    "Yarım",
            "fullGold":    "Tam",
            "USD":         "USD",
            "EUR":         "EUR",
        ]
        let items = gameState.rates.compactMap { rate -> String? in
            guard let label = labels[rate.type] else { return nil }
            let spotPrice = (rate.buyPrice + rate.sellPrice) / 2
            let isGold = rate.type.hasSuffix("Gold")
            let priceText = isGold ? FormatUtils.tl(spotPrice) : String(format: "₺%.2f", spotPrice)
            return "\(label) • \(priceText)"
        }
        return items.joined(separator: "     ")
    }

    // Fiyat verisinin tarihi (API'den gelir); henüz yüklenmemişse bugünün tarihi
    private var ratesDateString: String {
        let d = gameState.rates.first?.sourceDate ?? ""
        if !d.isEmpty { return d }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "tr_TR")
        fmt.dateFormat = "d MMMM yyyy"
        return fmt.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gdlBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        // MARK: 1. Etkinlik / Bilgi Kutucuğu (en üstte, kompakt)
                        eventOrTipBanner
                            .padding(.horizontal)

                        // MARK: 2. Profil Kartı (isim + tarih + stats)
                        profileCard
                            .padding(.horizontal)

                        // MARK: 3. Dükkanlarım + Pasif Gelir Topla
                        shopsCard
                            .padding(.horizontal)

                        // MARK: 4. Güncel Kurlar (3×2 grid, tek fiyat)
                        ratesCard
                            .padding(.horizontal)

                        // MARK: 5. Sıralama
                        rankingCard
                            .padding(.horizontal)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 12)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showCounter) {
            CounterView().environmentObject(gameState)
        }
        .alert("Gelir Toplandı!", isPresented: $showIncomeAlert) {
            Button("Harika!", role: .cancel) {}
        } message: {
            Text("Tüm dükkanlardan pasif gelir toplandı.")
        }
        .onAppear {
            tipIndex = Int.random(in: 0..<infoTips.count)
        }
    }

    // MARK: - Profil Kartı

    private var profileCard: some View {
        let hasImage = UIImage(named: "home_stats_bg") != nil
        return VStack(spacing: 0) {
            ZStack {
                // Arka plan: resim varsa resim, yoksa renk
                if hasImage {
                    Image("home_stats_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 185)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(red: 0.10, green: 0.08, blue: 0.04))
                        .frame(height: 185)
                }

                // Koyu gradient okunabilirlik için
                LinearGradient(
                    colors: [Color.black.opacity(0.65), Color.clear],
                    startPoint: .bottom, endPoint: .top
                )
                .frame(height: 185)

                // Sol üst: tarih kutucuğu
                VStack {
                    HStack {
                        Text(ratesDateString)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(7)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    Spacer()
                }

                // Alt: dükkan adı + tam genişlik kayan kur bandı
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    // Dükkan adı
                    Text(gameState.shopName)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    // Tam genişlik kayan bant
                    RateTickerView(text: ratesTickerText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(Color.black.opacity(0.35))
                }
            }
            .frame(height: 185)
            .clipped()

            Divider().background(Color.gdlDivider).padding(.horizontal, 16)

            // Alt: 3×2 stat grid
            HStack(spacing: 0) {
                statCell(label: "Nakit",       value: FormatUtils.tl(gameState.playerCash),    icon: "turkishlirasign.circle.fill", color: .gdlGold,   trailing: true)
                statCell(label: "Net Değer",   value: FormatUtils.tl(gameState.totalNetWorth), icon: "chart.bar.fill",               color: .gdlTextPrimary, trailing: false)
            }
            HStack(spacing: 0) {
                statCell(label: "Günlük Kâr", value: FormatUtils.tl(gameState.dailyProfit),   icon: "arrow.up.right",               color: gameState.dailyProfit >= 0 ? .gdlPositive : .gdlNegative, trailing: true)
                statCell(label: "Memnuniyet", value: "\(gameState.customerSatisfaction)/100",        icon: "face.smiling",                 color: satisfactionColor, trailing: false)
            }
            HStack(spacing: 0) {
                statCell(label: "Yaşam Puanı", value: "\(gameState.lifestyleScore) puan",            icon: "star.fill",                    color: .gdlGold,   trailing: true)
                statCell(label: "Dükkan",      value: "\(gameState.ownedShops.count) adet",          icon: "building.2.fill",              color: .gdlTextPrimary, trailing: false)
            }
        }
        .background(Color.gdlCard)
        .cornerRadius(16)
        .clipped()
    }

    private func statCell(label: String, value: String, icon: String, color: Color, trailing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2).foregroundColor(color.opacity(0.75))
                Text(label).font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
            }
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .trailing) {
            if trailing {
                Rectangle().frame(width: 1).foregroundColor(Color.gdlDivider)
            }
        }
    }

    // MARK: - Etkinlik veya Bilgi Kutucuğu

    @ViewBuilder
    private var eventOrTipBanner: some View {
        if let event = gameState.activeEvents.first(where: { $0.isActive }) {
            // Aktif etkinlik — altın şerit, kompakt
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.caption)
                    .foregroundColor(.black)
                    .frame(width: 16, height: 16)
                Text(event.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .fixedSize()
                    .lineLimit(1)
                Text("·")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.5))
                MarqueeTextView(
                    text: event.description,
                    font: .system(size: 12),
                    color: .black.opacity(0.75)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 18)
                Text("\(event.remainingDays)g")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(5)
                    .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gdlGold)
            .cornerRadius(10)
        } else {
            // Etkinlik yok — ince bilgi satırı
            let tip = infoTips[tipIndex]
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: tip.icon)
                    .font(.caption)
                    .foregroundColor(.gdlGold)
                    .frame(width: 16, height: 16)
                MarqueeTextView(
                    text: tip.text,
                    font: .system(size: 12),
                    color: .gdlTextSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 18)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gdlCard)
            .cornerRadius(10)
        }
    }

    // MARK: - Dükkanlarım Kartı (içinde pasif gelir butonu)

    private var shopsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Başlık
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill").foregroundColor(.gdlGold).font(.subheadline)
                Text("Dükkanlarım").font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().background(Color.gdlDivider).padding(.horizontal, 16)

            // Dükkan listesi
            ForEach(gameState.ownedShops) { shop in
                shopRow(shop: shop)
                if shop.id != gameState.ownedShops.last?.id {
                    Divider().background(Color.gdlDivider).padding(.leading, 68)
                }
            }

            Divider().background(Color.gdlDivider).padding(.horizontal, 16)

            // Pasif gelir topla (listenin altında)
            passiveIncomeRow
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color.gdlCard)
        .cornerRadius(16)
    }

    private func shopRow(shop: Shop) -> some View {
        Button {
            gameState.enterShop(shop)
            showCounter = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gdlGold.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: shop.locationType.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gdlGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(shop.name)
                        .font(.gdlBody())
                        .foregroundColor(.gdlTextPrimary)
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.gdlTextSecondary)
                        Text("\(shop.employeeCount)/\(shop.employeeCapacity) personel")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                        Text("·").foregroundColor(.gdlTextSecondary).font(.caption)
                        Text("₺\(FormatUtils.compact(shop.dailyPassiveBaseIncome))/gün")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("Gir")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gdlGold)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var passiveIncomeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pasif Gelir")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                Text(FormatUtils.tl(gameState.passiveIncomeAvailable))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(gameState.passiveIncomeCollectedToday ? .gdlTextSecondary : .gdlGold)
            }
            Spacer()
            Button {
                gameState.collectPassiveIncome()
                showIncomeAlert = true
            } label: {
                Label("Topla", systemImage: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gameState.passiveIncomeCollectedToday ? .gdlTextSecondary : .black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(gameState.passiveIncomeCollectedToday ? Color.gdlCardSecondary : Color.gdlGold)
                    .cornerRadius(10)
            }
            .disabled(gameState.passiveIncomeCollectedToday)
        }
    }

    // MARK: - Güncel Kurlar (3×2 grid, tek fiyat)

    private var ratesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.gdlGold).font(.subheadline)
                Text("Güncel Kurlar").font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
                Spacer()
                Text(gameState.rates.first?.sourceDate ?? "")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().background(Color.gdlDivider).padding(.horizontal, 16)

            // 3 satır × 2 sütun
            let pairs = ratesPaired()
            VStack(spacing: 0) {
                ForEach(0..<pairs.count, id: \.self) { row in
                    HStack(spacing: 0) {
                        rateCell(rate: pairs[row].0, trailing: true)
                        if let r2 = pairs[row].1 {
                            rateCell(rate: r2, trailing: false)
                        } else {
                            Spacer()
                        }
                    }
                    if row < pairs.count - 1 {
                        Divider().background(Color.gdlDivider).padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 4)

            Text("* Fiyat verileri genelpara.com adresinden alınmaktadır.")
                .font(.system(size: 10))
                .foregroundColor(.gdlTextSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .padding(.top, 4)
        }
        .background(Color.gdlCard)
        .cornerRadius(16)
    }

    // MARK: - Sıralama Kartı

    private let rankingPlayerID = UUID()

    private var rankingPlayerEntry: LeaderboardEntry {
        LeaderboardEntry(
            id: rankingPlayerID,
            playerName: "Sen (Benim Dükkanım)",
            dailyProfit: gameState.dailyProfit,
            weeklyProfit: gameState.weeklyProfit,
            monthlyRevenue: gameState.monthlyRevenue,
            netWorth: gameState.totalNetWorth,
            cashBalance: gameState.playerCash,
            lifestylePoints: gameState.lifestyleScore,
            isPlayer: true
        )
    }

    private var rankingCard: some View {
        let tabs = ["Toplam Servet", "Toplam Nakit", "Yaşam Puanı"]

        let allEntries: [LeaderboardEntry] = {
            var list = MockGameData.mockLeaderboard
            list.append(rankingPlayerEntry)
            return list
        }()

        let sorted: [LeaderboardEntry] = {
            switch rankingTab {
            case 1:  return allEntries.sorted { $0.cashBalance    > $1.cashBalance }
            case 2:  return allEntries.sorted { $0.lifestylePoints > $1.lifestylePoints }
            default: return allEntries.sorted { $0.netWorth       > $1.netWorth }
            }
        }()

        let playerRank  = (sorted.firstIndex(where: { $0.isPlayer }) ?? 0) + 1
        let top10       = Array(sorted.prefix(10))
        let playerInTop = playerRank <= 10

        return VStack(alignment: .leading, spacing: 0) {
            // Başlık
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundColor(.gdlGold).font(.subheadline)
                Text("Sıralama").font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Sekme seçici
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { rankingTab = i }
                    } label: {
                        Text(tabs[i])
                            .font(.system(size: 12, weight: rankingTab == i ? .semibold : .regular))
                            .foregroundColor(rankingTab == i ? .gdlGold : .gdlTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(rankingTab == i ? Color.gdlGold.opacity(0.12) : Color.clear)
                    }
                    if i < tabs.count - 1 {
                        Rectangle().fill(Color.gdlDivider).frame(width: 1, height: 28)
                    }
                }
            }
            .background(Color.gdlCardSecondary)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider().background(Color.gdlDivider).padding(.horizontal, 16)

            // İlk 10
            ForEach(Array(top10.enumerated()), id: \.element.id) { idx, entry in
                rankingRow(rank: idx + 1, entry: entry, tab: rankingTab)
                if idx < top10.count - 1 {
                    Divider().background(Color.gdlDivider).padding(.leading, 58)
                }
            }

            // Oyuncu ilk 10'da değilse ayrıca göster
            if !playerInTop {
                HStack {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                Divider().background(Color.gdlDivider).padding(.leading, 58)
                rankingRow(rank: playerRank, entry: rankingPlayerEntry, tab: rankingTab)
            }
        }
        .background(Color.gdlCard)
        .cornerRadius(16)
    }

    private func rankingRow(rank: Int, entry: LeaderboardEntry, tab: Int) -> some View {
        let valueText: String = {
            switch tab {
            case 1:  return FormatUtils.tlCompact(entry.cashBalance)
            case 2:  return "\(entry.lifestylePoints) puan"
            default: return FormatUtils.tlCompact(entry.netWorth)
            }
        }()

        return HStack(spacing: 12) {
            rankBadge(rank)
            Text(entry.isPlayer ? gameState.shopName : entry.playerName)
                .font(.gdlBody())
                .foregroundColor(entry.isPlayer ? .gdlGold : .gdlTextPrimary)
                .lineLimit(1)
            Spacer()
            Text(valueText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(entry.isPlayer ? .gdlGold : .gdlTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(entry.isPlayer ? Color.gdlGold.opacity(0.08) : Color.clear)
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        switch rank {
        case 1:
            Text("🥇").font(.system(size: 26)).frame(width: 36, height: 36)
        case 2:
            Text("🥈").font(.system(size: 26)).frame(width: 36, height: 36)
        case 3:
            Text("🥉").font(.system(size: 26)).frame(width: 36, height: 36)
        default:
            ZStack {
                Circle()
                    .fill(Color.gdlCardSecondary)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gdlTextSecondary)
            }
            .frame(width: 36, height: 36)
        }
    }

    private func rateCell(rate: Rate, trailing: Bool) -> some View {
        let spotPrice = (rate.buyPrice + rate.sellPrice) / 2
        let prevPrice = gameState.previousRatePrices[rate.type] ?? 0
        let isGold    = rate.type.hasSuffix("Gold")
        let priceText = isGold ? FormatUtils.tl(spotPrice) : String(format: "₺%.2f", spotPrice)
        let changeDir: Int = prevPrice > 0
            ? (spotPrice > prevPrice * 1.001 ? 1 : spotPrice < prevPrice * 0.999 ? -1 : 0)
            : 0

        return HStack(spacing: 8) {
            Image(systemName: rateIcon(for: rate.type))
                .font(.subheadline)
                .foregroundColor(.gdlGold)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(rate.name)
                    .font(.system(size: 11))
                    .foregroundColor(.gdlTextSecondary)
                HStack(spacing: 3) {
                    Text(priceText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gdlTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if changeDir == 1 {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gdlPositive)
                    } else if changeDir == -1 {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gdlNegative)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .trailing) {
            if trailing {
                Rectangle().frame(width: 1).foregroundColor(Color.gdlDivider)
            }
        }
    }

    private func ratesPaired() -> [(Rate, Rate?)] {
        let r = gameState.rates
        var result: [(Rate, Rate?)] = []
        var i = 0
        while i < r.count {
            let second: Rate? = (i + 1 < r.count) ? r[i + 1] : nil
            result.append((r[i], second))
            i += 2
        }
        return result
    }

    private func rateIcon(for type: String) -> String {
        switch type {
        case "gramGold":    return "circle.fill"
        case "quarterGold": return "circle.lefthalf.filled"
        case "halfGold":    return "circle.bottomhalf.filled"
        case "fullGold":    return "seal.fill"
        case "USD":         return "dollarsign.circle.fill"
        case "EUR":         return "eurosign.circle.fill"
        default:            return "chart.bar.fill"
        }
    }

    // MARK: - Yardımcılar

    private var satisfactionColor: Color {
        if gameState.customerSatisfaction >= 70 { return .gdlPositive }
        if gameState.customerSatisfaction >= 40 { return .orange }
        return .gdlNegative
    }
}

// MARK: - Marquee Text (ara sıra kayan yazı)

// MARK: - Rate Ticker (sürekli döngülü kur bandı — TimelineView tabanlı, cihaz uyumlu)

private struct RateTickerView: View {
    let text: String
    private let pixPerSec: Double = 38

    @State private var unitWidth: CGFloat = 0
    @State private var measured   = false
    @State private var startDate  = Date()

    private var fullText: String { text + "          " + text }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: unitWidth == 0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let raw     = CGFloat(elapsed * pixPerSec)
            let looped  = unitWidth > 0
                ? raw.truncatingRemainder(dividingBy: unitWidth)
                : 0

            GeometryReader { _ in
                Text(fullText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.88))
                    .fixedSize(horizontal: true, vertical: false)
                    .shadow(radius: 2)
                    .background(
                        GeometryReader { g in
                            Color.clear.onAppear {
                                guard !measured else { return }
                                measured  = true
                                unitWidth = g.size.width / 2
                                startDate = Date()
                            }
                        }
                    )
                    .offset(x: -looped)
            }
            .clipped()
        }
        .onDisappear {
            measured   = false
            unitWidth  = 0
            startDate  = Date()
        }
    }
}

private struct MarqueeTextView: View {
    let text: String
    let font: Font
    let color: Color

    @State private var offsetX: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var generation: Int = 0   // iptal mekanizması

    var body: some View {
        GeometryReader { containerGeo in
            Text(text)
                .font(font)
                .foregroundColor(color)
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    GeometryReader { textGeo in
                        Color.clear.onAppear {
                            // İlk görünümde ölçüleri kaydet ve kaydırmayı başlat
                            textWidth = textGeo.size.width
                            containerWidth = containerGeo.size.width
                            guard textWidth > containerWidth + 4 else { return }
                            scrollOnce(tw: textWidth, cw: containerWidth)
                        }
                    }
                )
                .offset(x: offsetX)
        }
        .clipped()
        .onAppear {
            // Sonraki sekme dönüşlerinde (ölçüler zaten mevcut): tekrar tetikle
            offsetX = 0
            generation += 1
            guard textWidth > containerWidth + 4 else { return }
            scrollOnce(tw: textWidth, cw: containerWidth)
        }
        .onDisappear {
            // Sayfa kapanınca bekleyen animasyonu iptal et
            generation += 1
            offsetX = 0
        }
    }

    private func scrollOnce(tw: CGFloat, cw: CGFloat) {
        let gen  = generation
        let dist = tw - cw + 20
        let dur  = min(7.0, Double(dist) / 40.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard generation == gen else { return }
            withAnimation(.linear(duration: dur)) { offsetX = -dist }
            DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.3) {
                guard generation == gen else { return }
                withAnimation(.none) { offsetX = 0 }
            }
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(range.upperBound, self))
    }
}

#Preview {
    HomeView().environmentObject(GameState())
}
