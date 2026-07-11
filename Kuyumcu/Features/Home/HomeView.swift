import SwiftUI
import Combine

// MARK: - Info Tips (etkinlik yokken gösterilir)
private let infoTips: [(icon: String, text: String)] = [
    ("scalemass.fill",        "Teklif verirken piyasa fiyatına yakın kalmak kârlılığı korur."),
    ("clock.badge.checkmark", "Pasif geliri her gün toplayarak nakit akışınızı artırın."),
    ("star.fill",             "Daha prestijli lokasyonlar daha fazla VIP müşteri getirir."),
    ("chart.line.uptrend.xyaxis", "Altın fiyatları döviz kurlarından doğrudan etkilenir."),
    ("person.2.fill",         "Personel yükseltmesi pasif gelir çarpanınızı artırır."),
    ("shield.fill",           "Güvenlik yükseltmesi dolandırıcılık riskini azaltır."),
]

struct HomeView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    @StateObject private var adManager = AdManager.shared
    @State private var showCounter      = false
    @State private var showIncomeAlert      = false
    @State private var lastCollectedAmount: Double = 0
    @State private var showSocialFeed = false
    @State private var showDailyReward  = false
    @State private var showSpinWheel = false
    @State private var tipIndex         = Int.random(in: 0..<infoTips.count)
    @State private var rankingTab       = 0
    @State private var passiveIncomeNow = Date()
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var leaderboardLoading = false
    @State private var leaderboardUpdatedAt: Date?
    @State private var selectedShopForEntry: Shop?
    @State private var showEntryConfirmDialog = false
    @State private var showEntryRightsExhaustedDialog = false
    @State private var showAdNotReadyAlert = false
    @State private var showTaxDebtDialog = false

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
            let isGold = rate.type.hasSuffix("Gold")
            let priceText = isGold ? FormatUtils.tl(rate.sellPrice) : String(format: "₺%.2f", rate.sellPrice)
            return "\(label) • \(priceText)"
        }
        return items.joined(separator: "     ")
    }

    // Fiyat güncellenme zamanı; "19 Mayıs 2026 • 08:00" formatında
    private var ratesTimestampString: String {
        let raw = gameState.rates.first?.sourceDate ?? ""
        let displayFmt = DateFormatter()
        displayFmt.locale = Locale(identifier: "tr_TR")
        displayFmt.timeZone = TimeZone(identifier: "Europe/Istanbul")
        displayFmt.dateFormat = "d MMMM yyyy • HH:mm"
        if let date = parseRateDate(raw) {
            return displayFmt.string(from: date)
        }
        return ""
    }

    private func parseRateDate(_ raw: String) -> Date? {
        let fractionalISO = ISO8601DateFormatter()
        fractionalISO.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalISO.date(from: raw) {
            return date
        }

        if let date = ISO8601DateFormatter().date(from: raw) {
            return date
        }

        let trDateFormatter = DateFormatter()
        trDateFormatter.locale = Locale(identifier: "tr_TR")
        trDateFormatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        trDateFormatter.dateFormat = "d MMMM yyyy"
        return trDateFormatter.date(from: raw)
    }

    var body: some View {
        rootContent
    }

    private var rootContent: some View {
        ZStack {
            scrollContent
        }
        .gdlScreenBackground()
        .fullScreenCover(isPresented: $showCounter) {
            CounterView().environmentObject(gameState)
        }
        .overlay { socialFeedOverlay }
        .overlay { dailyRewardOverlay }
        .overlay { spinWheelOverlay }
        .overlay { taxDebtOverlay }
        .animation(.easeInOut(duration: 0.2), value: showSocialFeed)
        .animation(.easeInOut(duration: 0.2), value: showDailyReward)
        .animation(.easeInOut(duration: 0.2), value: showSpinWheel)
        .animation(.easeInOut(duration: 0.2), value: showTaxDebtDialog)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            passiveIncomeNow = now
        }
        .alert("Gelir Toplandı! 💰", isPresented: $showIncomeAlert) {
            Button("Harika!", role: .cancel) {}
        } message: {
            Text("\(FormatUtils.tl(lastCollectedAmount)) hesabına eklendi.")
        }
        .alert("Dükkana Gir", isPresented: $showEntryConfirmDialog, presenting: selectedShopForEntry) { shop in
            Button("İptal", role: .cancel) {
                selectedShopForEntry = nil
            }
            Button("Giriş") {
                if gameState.consumeEntryRightAndEnterShop(shop) {
                    showCounter = true
                }
                selectedShopForEntry = nil
            }
        } message: { _ in
            Text("Kalan giriş hakkın \(gameState.entryRightsRemaining)/3. Bu dükkana girersen 1 hak harcanır.")
        }
        .alert("Giriş Hakkın Bitti", isPresented: $showEntryRightsExhaustedDialog) {
            Button("İptal", role: .cancel) {}
            Button("Yenile") {
                refreshEntryRightsFromAd()
            }
        } message: {
            Text("Giriş hakkın bitti. Reklam izleyerek 3/3 yenileyebilirsin.")
        }
        .alert("Reklam Hazır Değil", isPresented: $showAdNotReadyAlert) {
            Button("Tamam", role: .cancel) {
                adManager.loadAd()
            }
        } message: {
            Text("Reklam yükleniyor, biraz sonra tekrar dene.")
        }
        .onAppear(perform: handleOnAppear)
        .onChange(of: gameState.taxDebt) { _, newValue in
            showTaxDebtDialog = newValue > 0
        }
        .onChange(of: gameState.rates.first?.sourceDate) { _, _ in
            Task { await refreshLeaderboard() }
        }
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GDLSpacing.md) {
                eventOrTipBanner
                    .padding(.horizontal)

                profileCard
                    .padding(.horizontal)

                shopsCard
                    .padding(.horizontal)

                ratesCard
                    .padding(.horizontal)

                rankingCard
                    .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top, GDLSpacing.md)
        }
    }

    @ViewBuilder
    private var socialFeedOverlay: some View {
        if showSocialFeed {
            SocialFeedView(isPresented: $showSocialFeed)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(9)
        }
    }

    @ViewBuilder
    private var dailyRewardOverlay: some View {
        if showDailyReward {
            DailyRewardView(isPresented: $showDailyReward)
                .environmentObject(gameState)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(10)
        }
    }

    @ViewBuilder
    private var spinWheelOverlay: some View {
        if showSpinWheel {
            SpinWheelView(isPresented: $showSpinWheel)
                .environmentObject(gameState)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(11)
        }
    }

    @ViewBuilder
    private var taxDebtOverlay: some View {
        if showTaxDebtDialog {
            TaxDebtPopupView(
                isPresented: $showTaxDebtDialog,
                taxDebt: gameState.taxDebt,
                playerCash: gameState.playerCash,
                canPayTax: gameState.canPayTax,
                onPay: {
                    if gameState.payTax() {
                        showTaxDebtDialog = false
                    }
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .zIndex(12)
        }
    }

    private func handleOnAppear() {
        tipIndex = Int.random(in: 0..<infoTips.count)
        gameState.syncEntryRightsIfNeeded()
        gameState.syncProfitPeriodsIfNeeded(persistsChanges: true, syncsCloud: false)
        showTaxDebtDialog = gameState.hasOutstandingTax
        if leaderboardEntries.isEmpty {
            Task { await refreshLeaderboard() }
        }
    }

    // MARK: - Profil Kartı

    private var profileCard: some View {
        let hasImage = UIImage(named: "home_stats_bg") != nil
        let showEntryRefreshPill = gameState.entryRightsRemaining == 0
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
                    colors: [Color.black.opacity(0.5), Color.clear],
                    startPoint: .bottom, endPoint: .top
                )
                .frame(height: 185)

                // Sol üst sosyal akış
                VStack {
                    HStack {
                        Button { showSocialFeed = true } label: {
                            ZStack {
                                if UIImage(named: "social_feed_button_icon") != nil {
                                    Image("social_feed_button_icon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 56, height: 56)
                                } else {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gdlGold)
                                        .padding(10)
                                        .background(Color.black.opacity(0.45))
                                        .clipShape(Circle())
                                        .frame(width: 56, height: 56)
                                }
                            }
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, GDLSpacing.lg)
                    .padding(.top, GDLSpacing.md)
                    Spacer()
                }

                // Sağ üst aksiyonlar
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: GDLSpacing.sm) {
                            Button { showDailyReward = true } label: {
                                ZStack {
                                    if UIImage(named: "daily_reward_button_icon") != nil {
                                        Image("daily_reward_button_icon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                    } else {
                                        Image(systemName: "gift.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.gdlGold)
                                            .padding(10)
                                            .background(Color.black.opacity(0.45))
                                            .clipShape(Circle())
                                            .frame(width: 56, height: 56)
                                    }
                                }
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)

                            Button { showSpinWheel = true } label: {
                                ZStack {
                                    if UIImage(named: "spin_button_icon") != nil {
                                        Image("spin_button_icon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                    } else {
                                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.gdlGold)
                                            .padding(10)
                                            .background(Color.black.opacity(0.45))
                                            .clipShape(Circle())
                                            .frame(width: 56, height: 56)
                                    }
                                }
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, GDLSpacing.lg)
                    .padding(.top, GDLSpacing.md)
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
                        .padding(.horizontal, GDLSpacing.lg)
                        .padding(.bottom, GDLSpacing.sm)
                    // Tam genişlik kayan bant
                    RateTickerView(text: ratesTickerText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(Color.black.opacity(0.35))
                }
            }
            .frame(height: 185)
            .clipped()

            Rectangle()
                .fill(Color.gdlDivider)
                .frame(height: 1)

            // Alt: 3×2 stat grid
            HStack(spacing: 0) {
                statCell(label: "Net Değer",   value: FormatUtils.tl(gameState.totalNetWorth), icon: "chart.bar.fill",               valueColor: .gdlGold, iconColor: .gdlGold, trailing: true)
                statCell(label: "Nakit",       value: FormatUtils.tl(gameState.playerCash),    icon: "turkishlirasign.circle.fill", valueColor: .gdlGold, iconColor: .gdlGold, trailing: false)
            }
            HStack(spacing: 0) {
                statCell(label: "Günlük Kâr", value: FormatUtils.tl(gameState.dailyProfit),   icon: "arrow.up.right",               valueColor: gameState.dailyProfit >= 0 ? .gdlPositive : .gdlNegative, iconColor: .gdlTextPrimary, trailing: true)
                statCell(
                    label: "Giriş Hakkı",
                    value: "\(gameState.entryRightsRemaining)/3",
                    icon: "door.left.hand.open",
                    valueColor: showEntryRefreshPill ? .gdlNegative : .gdlPositive,
                    iconColor: .gdlTextPrimary,
                    trailing: false,
                    badgeTitle: showEntryRefreshPill ? "Yenile" : nil,
                    badgeAction: showEntryRefreshPill ? { refreshEntryRightsFromAd() } : nil
                )
            }
            HStack(spacing: 0) {
                statCell(label: "Yaşam Puanı", value: "\(gameState.lifestyleScore) puan",            icon: "star.fill",                    valueColor: .gdlTextPrimary, iconColor: .gdlTextPrimary, trailing: true)
                statCell(label: "Dükkan",      value: "\(gameState.ownedShops.count) adet",          icon: "building.2.fill",              valueColor: .gdlTextPrimary, iconColor: .gdlTextPrimary, trailing: false)
            }
        }
        .gdlOuterSurface(radius: GDLRadius.cardOuterRadius)
    }

    private func statCell(
        label: String,
        value: String,
        icon: String,
        valueColor: Color,
        iconColor: Color,
        trailing: Bool,
        badgeTitle: String? = nil,
        badgeAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: GDLSpacing.xxs) {
            HStack(spacing: GDLSpacing.xxs) {
                Image(systemName: icon).font(.caption2).foregroundColor(iconColor)
                Text(label).font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
            }
            HStack(spacing: GDLSpacing.xs) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let badgeTitle, let badgeAction {
                    Button(action: badgeAction) {
                        Text(badgeTitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, GDLSpacing.xs)
                            .padding(.vertical, 4)
                            .background(Color.gdlGold)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, GDLSpacing.lg)
        .padding(.vertical, GDLSpacing.sm)
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
            HStack(alignment: .center, spacing: GDLSpacing.sm) {
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
                    .padding(.horizontal, GDLSpacing.xs)
                    .padding(.vertical, GDLSpacing.xxxs)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(GDLRadius.sm)
                    .fixedSize()
            }
            .padding(.horizontal, GDLSpacing.md)
            .padding(.vertical, GDLSpacing.sm)
            .background(Color.gdlGold)
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))
        } else {
            // Etkinlik yok — ince bilgi satırı
            let tip = infoTips[tipIndex]
            HStack(alignment: .center, spacing: GDLSpacing.sm) {
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
            .padding(.horizontal, GDLSpacing.md)
            .padding(.vertical, GDLSpacing.sm)
            .background(Color.gdlCard)
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))
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
        .gdlOuterSurface(radius: GDLRadius.cardOuterRadius)
    }

    private func shopRow(shop: Shop) -> some View {
        let hourlyPassiveIncome = shop.locationType.passiveTick * 360 * gameState.employeeMultiplier(for: shop)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(LinearGradient.gdlGoldButton, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                ZStack {
                    LinearGradient.gdlGoldButton
                        .mask(
                            Image(systemName: shop.locationType.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 20, height: 20)
                        )
                }
                .frame(width: 20, height: 20)
            }
            .frame(width: 44, height: 44)

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
                    Text("\(FormatUtils.tl(hourlyPassiveIncome))/saat")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                CompactActionButton(title: "Gir", icon: "chevron.right", iconTrailing: true, style: .goldGradient) {
                    audioManager.playEffect(.buttonTap)
                    promptEntry(for: shop)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var passiveIncomeRow: some View {
        let income = gameState.passiveIncomeAvailable(at: passiveIncomeNow)
        let hasIncome  = income > 0
        let adReady    = adManager.isAdReady
        let canCollect = hasIncome && adReady

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pasif Gelir")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                Text(FormatUtils.tl(income))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(hasIncome ? .gdlGold : .gdlTextSecondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            if adManager.isLoading {
                HStack(spacing: 6) {
                    ProgressView().tint(.gdlTextSecondary).scaleEffect(0.75)
                    Text("Hazırlanıyor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gdlTextSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .gdlSecondarySurface(radius: GDLRadius.sm)
            } else {
                CompactActionButton(
                    title: "İzle & Topla",
                    icon: "play.rectangle.fill",
                    style: .goldGradient,
                    isDisabled: !canCollect
                ) {
                    audioManager.playEffect(.buttonTap)
                    adManager.showAd {
                        let amount = gameState.passiveIncomeAvailable
                        gameState.collectPassiveIncome()
                        audioManager.playEffect(.passiveCollect)
                        lastCollectedAmount = amount
                        showIncomeAlert = true
                    } onUnavailable: {
                        showAdNotReadyAlert = true
                    }
                }
                .disabled(!canCollect)
            }
        }
    }

    // MARK: - Güncel Kurlar (3×2 grid, tek fiyat)

    private var ratesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.gdlGold).font(.subheadline)
                Text("Güncel Kurlar").font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
                Spacer()
                Text(ratesTimestampString)
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
                }
            }
            .padding(.vertical, 4)

            Text("* Fiyat verileri finans.truncgil.com adresinden alınmaktadır.")
                .font(.system(size: 10))
                .foregroundColor(.gdlTextSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .padding(.top, 4)
        }
        .gdlOuterSurface(radius: GDLRadius.cardOuterRadius)
    }

    // MARK: - Sıralama Kartı

    private var leaderboardUpdatedDateString: String {
        guard let leaderboardUpdatedAt else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: leaderboardUpdatedAt)
    }

    private var rankingCard: some View {
        let tabs = ["Toplam Servet", "Toplam Nakit", "Yaşam Puanı"]
        let rankedEntries = leaderboardRankedEntries

        return VStack(alignment: .leading, spacing: 0) {
            // Başlık
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundColor(.gdlGold).font(.subheadline)
                Text("Kuyumcular").font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
                Spacer()
                if !leaderboardUpdatedDateString.isEmpty {
                    Text(leaderboardUpdatedDateString)
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }
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
            .gdlSecondarySurface(radius: GDLRadius.sm)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider().background(Color.gdlDivider).padding(.horizontal, 16)

            // İlk 10
            if leaderboardLoading && rankedEntries.isEmpty {
                HStack(spacing: 10) {
                    ProgressView().tint(.gdlGold)
                    Text("Sıralama yükleniyor...")
                        .font(.system(size: 13))
                        .foregroundColor(.gdlTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else if rankedEntries.isEmpty {
                Text("Henüz yeterli oyuncu verisi yok.")
                    .font(.system(size: 13))
                    .foregroundColor(.gdlTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }

            ForEach(Array(rankedEntries.enumerated()), id: \.element.entry.id) { idx, ranked in
                rankingRow(rank: ranked.rank, entry: ranked.entry, tab: rankingTab)
                if idx < rankedEntries.count - 1 {
                    Divider().background(Color.gdlDivider).padding(.leading, 58)
                }
            }
        }
        .gdlOuterSurface(radius: GDLRadius.cardOuterRadius)
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
            Text(entry.playerName)
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
        let isGold    = rate.type.hasSuffix("Gold")
        let priceText = isGold ? FormatUtils.tl(rate.sellPrice) : String(format: "₺%.2f", rate.sellPrice)
        let changeDir = rate.changeDir

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
                    } else {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gdlGold)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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

    private var leaderboardRankedEntries: [(rank: Int, entry: LeaderboardEntry)] {
        let currentUserId = AuthService.shared.userId
        let normalizedEntries = leaderboardEntries.map { entry in
            var normalized = entry
            normalized.isPlayer = entry.id == currentUserId
            return normalized
        }
        let sorted = normalizedEntries.sorted { lhs, rhs in
            switch rankingTab {
            case 1:
                return lhs.cashBalance > rhs.cashBalance
            case 2:
                return lhs.lifestylePoints > rhs.lifestylePoints
            default:
                return lhs.netWorth > rhs.netWorth
            }
        }

        var ranked = Array(sorted.prefix(10)).enumerated().map { (rank: $0.offset + 1, entry: $0.element) }
        if let currentUserId,
           !ranked.contains(where: { $0.entry.id == currentUserId }),
           let playerRank = sorted.firstIndex(where: { $0.id == currentUserId }) {
            ranked.append((rank: playerRank + 1, entry: sorted[playerRank]))
        }
        return ranked
    }

    private func refreshLeaderboard() async {
        await MainActor.run { leaderboardLoading = true }
        let snapshot = await SupabaseSaveService.fetchDailyLeaderboardSnapshot()
        await MainActor.run {
            leaderboardEntries = snapshot?.entries ?? []
            leaderboardUpdatedAt = snapshot?.updatedAt
            leaderboardLoading = false
        }
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

    private func promptEntry(for shop: Shop) {
        gameState.syncProfitPeriodsIfNeeded(persistsChanges: true, syncsCloud: false)
        gameState.syncEntryRightsIfNeeded()
        selectedShopForEntry = shop

        if gameState.hasOutstandingTax {
            showTaxDebtDialog = true
            return
        }

        if gameState.canEnterShop {
            showEntryConfirmDialog = true
        } else {
            showEntryRightsExhaustedDialog = true
        }
    }

    private func refreshEntryRightsFromAd() {
        guard adManager.isAdReady else {
            adManager.loadAd()
            showAdNotReadyAlert = true
            return
        }

        adManager.showAd {
            gameState.refreshEntryRightsFromAd()
        }
    }
}

private struct TaxDebtPopupView: View {
    @Binding var isPresented: Bool
    let taxDebt: Double
    let playerCash: Double
    let canPayTax: Bool
    let onPay: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: GDLSpacing.md) {
                VStack(spacing: GDLSpacing.xs) {
                    Text("Vergi Borcu")
                        .font(.gdlTitle())
                        .foregroundColor(.gdlTextPrimary)
                    Text("Ödemen gereken vergi: \(FormatUtils.tl(taxDebt))")
                        .font(.gdlBody())
                        .foregroundColor(.gdlGold)
                    if canPayTax {
                        Text("Nakit bakiyen yeterli. Ödeyip tezgaha giriş yapabilirsin.")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Nakit yetersiz. Envanterinden satış yaparak nakit oluşturup vergini ödeyebilirsin.")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: GDLSpacing.xs) {
                    HStack {
                        Text("Mevcut Nakit")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                        Spacer()
                        Text(FormatUtils.tl(playerCash))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(canPayTax ? .gdlPositive : .gdlNegative)
                    }

                    HStack(spacing: GDLSpacing.sm) {
                        Button("Tamam") {
                            isPresented = false
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gdlTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gdlCardSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))

                        Button("Öde") {
                            onPay()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canPayTax ? AnyShapeStyle(LinearGradient.gdlGoldButton) : AnyShapeStyle(Color.gdlCardSecondary))
                        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))
                        .disabled(!canPayTax)
                        .opacity(canPayTax ? 1 : 0.55)
                    }
                }
            }
            .padding(GDLSpacing.lg)
            .frame(maxWidth: 340)
            .gdlOuterSurface(radius: GDLRadius.shellOuterRadius)
            .padding(.horizontal, GDLSpacing.lg)
        }
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
    HomeView()
        .environmentObject(GameState())
        .environmentObject(AudioManager.shared)
}
