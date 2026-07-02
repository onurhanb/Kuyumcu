import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    @StateObject private var adManager = AdManager.shared
    @StateObject private var consentManager = ConsentManager.shared
    @StateObject private var pushService = PushNotificationService.shared

    @State private var showResetAlert    = false
    @State private var showSignOutAlert  = false
    @State private var showAdUnavailable = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountFinalAlert = false
    @State private var showDeleteAccountError = false
    @State private var isWatchingAd      = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountErrorMessage = ""

    // MARK: - Günlük reset hakkı
    private let resetKey = "lastResetDate"

    private var canResetToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: resetKey) as? Date else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    private func markResetUsed() {
        UserDefaults.standard.set(Date(), forKey: resetKey)
    }

    var body: some View {
        ZStack {
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

                    // 4. Envanter (ikonlu)
                    inventoryCard
                        .padding(.horizontal)

                    // Ayarlar
                    SectionCard(title: "Ayarlar", icon: "gearshape.fill") {
                        musicToggleRow("Genel Müzik", icon: "music.note",
                                       binding: Binding(
                                           get: { audioManager.isGeneralMusicEnabled },
                                           set: { audioManager.isGeneralMusicEnabled = $0 }
                                       ))
                        Divider().background(Color.gdlDivider)
                        musicToggleRow("Tezgah Müziği", icon: "music.quarternote.3",
                                       binding: Binding(
                                           get: { audioManager.isCounterMusicEnabled },
                                           set: { audioManager.isCounterMusicEnabled = $0 }
                                       ))
                        Divider().background(Color.gdlDivider)
                        musicToggleRow("Ses Efektleri", icon: "speaker.wave.2.fill",
                                       binding: Binding(
                                           get: { audioManager.isSoundEffectsEnabled },
                                           set: { audioManager.isSoundEffectsEnabled = $0 }
                                       ))
                        Divider().background(Color.gdlDivider)
                        musicToggleRow("Günlük Kur Bildirimi", icon: "bell.badge.fill",
                                       binding: Binding(
                                           get: { pushService.dailyRateNotificationsEnabled },
                                           set: { isEnabled in
                                               Task {
                                                   await pushService.setDailyRateNotificationsEnabled(isEnabled)
                                               }
                                           }
                                       ))
                        Divider().background(Color.gdlDivider)
                        Button {
                            pushService.openSystemNotificationSettings()
                        } label: {
                            actionSettingRow("Bildirim Ayarları", icon: "bell.fill")
                        }
                        .buttonStyle(.plain)
                        Divider().background(Color.gdlDivider)
                        settingRow("Uygulama Versiyonu", value: appVersionText)
                    }
                    .padding(.horizontal)

                    syncCard
                        .padding(.horizontal)

                    // Hesaptan Çıkış butonu
                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                            Text("Hesaptan Çıkış Yap")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.gdlGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gdlGold.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Hesap silme butonu
                    Button {
                        showDeleteAccountAlert = true
                    } label: {
                        HStack(spacing: 10) {
                            if isDeletingAccount {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))
                            }
                            Text(isDeletingAccount ? "Hesap Siliniyor..." : "Hesabımı Sil")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gdlNegative.opacity(isDeletingAccount ? 0.55 : 0.85))
                        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))
                    }
                    .disabled(isDeletingAccount)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if consentManager.isPrivacyOptionsRequired {
                        Button {
                            Task { await consentManager.presentPrivacyOptions() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 18))
                                Text("Gizlilik Seçenekleri")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.gdlTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .gdlSecondarySurface(radius: GDLRadius.sm)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    // Oyunu Sıfırla butonu
                    Button {
                        if !canResetToday {
                            showAdUnavailable = true
                            return
                        }
                        if adManager.isAdReady {
                            isWatchingAd = true
                            adManager.showAd {
                                isWatchingAd = false
                                showResetAlert = true
                            }
                        } else {
                            // Reklam yüklenmediyse yeniden dene
                            adManager.loadAd()
                            showAdUnavailable = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isWatchingAd {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: canResetToday
                                      ? "arrow.counterclockwise.circle.fill"
                                      : "lock.circle.fill")
                                    .font(.system(size: 18))
                            }
                            Text(canResetToday ? "Oyunu Sıfırla" : "Bugünlük Sıfırlama Hakkı Kullanıldı")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canResetToday ? Color.gdlNegative : Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.sm))
                    }
                    .disabled(!canResetToday || isWatchingAd)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer(minLength: 80)
                }
                .padding(.top, 12)
            }
        }
        .gdlScreenBackground()
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .alert("Hesaptan Çıkış", isPresented: $showSignOutAlert) {
            Button("Çıkış Yap", role: .destructive) {
                Task { try? await AuthService.shared.signOut() }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Hesabından çıkış yapılacak. Verilerın bulutta güvende, tekrar giriş yapabilirsin.")
        }
        .alert("Hesap Silme", isPresented: $showDeleteAccountAlert) {
            Button("Devam Et", role: .destructive) {
                showDeleteAccountFinalAlert = true
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu işlem hesabını, bulut kaydını, dükkanlarını, envanterini ve oyun ilerlemeni kalıcı olarak siler.")
        }
        .alert("Son Onay", isPresented: $showDeleteAccountFinalAlert) {
            Button("Kalıcı Olarak Sil", role: .destructive) {
                deleteAccount()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu işlem geri alınamaz. Hesabın ve bağlı oyun verilerin kalıcı olarak silinecek.")
        }
        .alert("Hesap Silinemedi", isPresented: $showDeleteAccountError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(deleteAccountErrorMessage)
        }
        .alert("Oyunu Sıfırla", isPresented: $showResetAlert) {
            Button("Sıfırla", role: .destructive) {
                markResetUsed()
                gameState.resetGame()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Dükkan adın korunur; nakit, envanter, dükkanlar, personel, pasif gelir, istatistikler ve yaşam tarzı ilerlemesi başlangıç durumuna döner. Bu işlem geri alınamaz.")
        }
        .alert("Reklam Hazır Değil", isPresented: $showAdUnavailable) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(canResetToday
                 ? "Reklam yükleniyor, biraz sonra tekrar dene."
                 : "Bugünlük sıfırlama hakkını kullandın. Yarın tekrar dene.")
        }
    }

    private func deleteAccount() {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true

        Task {
            do {
                try await AuthService.shared.deleteAccount()
                await MainActor.run {
                    gameState.resetLocalProgress()
                    isDeletingAccount = false
                }
            } catch {
                await MainActor.run {
                    deleteAccountErrorMessage = error.localizedDescription
                    showDeleteAccountError = true
                    isDeletingAccount = false
                }
            }
        }
    }

    private var syncCard: some View {
        SectionCard(title: "Bulut Senkron", icon: "arrow.triangle.2.circlepath") {
            HStack(spacing: 10) {
                syncStatusIcon
                VStack(alignment: .leading, spacing: 4) {
                    Text(syncStatusTitle)
                        .font(.gdlBody())
                        .foregroundColor(.gdlTextPrimary)
                    if let detail = syncStatusDetail {
                        Text(detail)
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                if gameState.cloudSyncStatus == .failed {
                    CompactActionButton(title: "Tekrar Dene", style: .gold) {
                        gameState.retryCloudSync()
                    }
                } else if gameState.cloudSyncStatus == .syncing {
                    ProgressView()
                        .tint(.gdlGold)
                }
            }
        }
    }

    private var syncStatusTitle: String {
        switch gameState.cloudSyncStatus {
        case .idle:
            return "Henüz senkron yapılmadı"
        case .syncing:
            return "Bulut senkron devam ediyor"
        case .synced:
            return "Bulut senkron tamamlandı"
        case .failed:
            return "Bulut senkron başarısız"
        }
    }

    private var syncStatusDetail: String? {
        switch gameState.cloudSyncStatus {
        case .idle:
            return "Kalıcı bir işlem yaptığında veriler otomatik olarak buluta yazılır."
        case .syncing:
            return "Son değişikliklerin buluta kaydediliyor."
        case .synced:
            if let date = gameState.cloudSyncUpdatedAt {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "tr_TR")
                formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
                formatter.dateFormat = "d MMMM yyyy • HH:mm"
                return "Son başarılı senkron: \(formatter.string(from: date))"
            }
            return "Son değişikliklerin buluta kaydedildi."
        case .failed:
            return gameState.cloudSyncErrorMessage ?? "Bulut kaydı tamamlanamadı. Tekrar deneyebilirsin."
        }
    }

    @ViewBuilder
    private var syncStatusIcon: some View {
        switch gameState.cloudSyncStatus {
        case .idle:
            Image(systemName: "icloud")
                .foregroundColor(.gdlTextSecondary)
                .frame(width: 22)
        case .syncing:
            Image(systemName: "icloud.and.arrow.up")
                .foregroundColor(.gdlGold)
                .frame(width: 22)
        case .synced:
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.gdlPositive)
                .frame(width: 22)
        case .failed:
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(.gdlNegative)
                .frame(width: 22)
        }
    }

    // MARK: - 1. Profil Kartı

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: GDLRadius.lg)
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
                if let uid = AuthService.shared.userId {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.gdlTextSecondary.opacity(0.6))
                        Text("ID: \(uid.uuidString.prefix(8).uppercased())")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gdlTextSecondary.opacity(0.6))
                    }
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
                    finCell(label: "Toplam İşlem",   value: "\(gameState.totalTransactions)", color: .gdlTextPrimary, trailing: true)
                    finCell(label: "Kabul Oranı",    value: acceptanceRateText,              color: .gdlTextPrimary, trailing: false)
                }
            }

            Divider().background(Color.gdlDivider).padding(.horizontal, 14)

            // Servet dağılım grafiği
            wealthBreakdownChart
                .padding(14)
        }
        .gdlOuterSurface(radius: GDLRadius.cardOuterRadius)
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

    private var acceptanceRateText: String {
        guard gameState.totalTransactions > 0 else { return "%0" }
        let rate = Int((Double(gameState.acceptedDeals) / Double(gameState.totalTransactions)) * 100)
        return "%\(rate)"
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
                        LazyVGrid(columns: lifestyleGridColumns, spacing: 8) {
                            ForEach(ownedInCat) { item in
                                lifestyleThumb(item: item)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
                let thumbRadius = GDLSpacing.sm
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gdlCardSecondary)
                    .aspectRatio(1, contentMode: .fit)

                if hasImage {
                    Image(imgKey)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: thumbRadius))
                } else {
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.gdlGold)
                }
            }

            Text(item.name)
                .font(.system(size: 8))
                .foregroundColor(.gdlTextSecondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
    }

    private var lifestyleGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 56, maximum: 72), spacing: 8)]
    }

    /// "Espresso Makinesi" → "lifestyle_espresso_makinesi"
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
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        return "lifestyle_\(slug)"
    }

    // MARK: - 4. Envanter (ikonlu)

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

    private func musicToggleRow(_ label: String, icon: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.gdlGold)
                .frame(width: 22)
            Text(label).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.gdlGold)
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

    private func actionSettingRow(_ label: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.gdlGold)
                .frame(width: 22)
            Text(label).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gdlDivider)
        }
        .padding(.vertical, 3)
    }

    private var appVersionText: String {
        AppVersion.current.displayText
    }
}

#Preview {
    NavigationStack { ProfileView().environmentObject(GameState()) }
}
