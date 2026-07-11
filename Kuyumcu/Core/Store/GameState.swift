import Foundation
import Combine

enum CloudSyncStatus {
    case idle
    case syncing
    case synced
    case failed
}

@MainActor
class GameState: ObservableObject {
    enum DailyRewardKind {
        case cash(Double)
        case spinRights(Int)

        var iconName: String {
            switch self {
            case .cash:
                return "banknote.fill"
            case .spinRights:
                return "arrow.trianglehead.2.clockwise.rotate.90.circle.fill"
            }
        }
    }

    enum WheelReward: String, CaseIterable, Identifiable {
        case tl10k
        case half1
        case usd1000
        case tl20k
        case quarter1
        case tl40k
        case spinRights2
        case tl50k
        case eur1000
        case gram1
        case tl30k
        case full1

        var id: String { rawValue }

        var shortLabel: String {
            switch self {
            case .tl10k: return "₺10K"
            case .tl20k: return "₺20K"
            case .tl30k: return "₺30K"
            case .tl40k: return "₺40K"
            case .tl50k: return "₺50K"
            case .spinRights2: return "x2"
            case .usd1000: return "$1K"
            case .eur1000: return "€1K"
            case .gram1: return "Gram"
            case .quarter1: return "Çeyrek"
            case .half1: return "Yarım"
            case .full1: return "Tam"
            }
        }

        var displayTitle: String {
            switch self {
            case .tl10k: return "10.000 TL"
            case .tl20k: return "20.000 TL"
            case .tl30k: return "30.000 TL"
            case .tl40k: return "40.000 TL"
            case .tl50k: return "50.000 TL"
            case .spinRights2: return "2 Çark Hakkı"
            case .usd1000: return "1000 Dolar"
            case .eur1000: return "1000 Euro"
            case .gram1: return "1 Gram Altın"
            case .quarter1: return "1 Çeyrek Altın"
            case .half1: return "1 Yarım Altın"
            case .full1: return "1 Tam Altın"
            }
        }

        var weight: Int {
            switch self {
            case .tl10k: return 18
            case .tl20k: return 16
            case .tl30k: return 12
            case .tl40k: return 8
            case .tl50k: return 5
            case .spinRights2: return 4
            case .usd1000: return 10
            case .eur1000: return 10
            case .gram1: return 8
            case .quarter1: return 4
            case .half1: return 3
            case .full1: return 2
            }
        }

        var accentColorName: String {
            switch self {
            case .tl10k, .tl20k, .tl30k, .tl40k, .tl50k:
                return "cash"
            case .spinRights2:
                return "rights"
            case .usd1000, .eur1000:
                return "fx"
            case .gram1, .quarter1, .half1, .full1:
                return "gold"
            }
        }
    }

    private enum InventoryBucket: Hashable {
        case gramGold
        case quarterGold
        case halfGold
        case fullGold
        case usd
        case eur
    }

    // MARK: - Finances
    @Published var playerCash: Double
    @Published var inventory: Inventory

    // MARK: - Market Rates
    @Published var rates: [Rate]

    // MARK: - Shops
    @Published var ownedShops: [Shop]
    @Published var lockedShops: [Shop]
    @Published var activeShop: Shop?

    // MARK: - Progression
    @Published var entryRightsRemaining: Int
    @Published var spinRightsRemaining: Int
    @Published var totalProfit: Double
    @Published var dailyProfit: Double
    @Published var weeklyProfit: Double
    @Published var monthlyRevenue: Double
    @Published var taxDebt: Double
    @Published var lastTaxChargedDay: Int
    @Published var currentDay: Int
    @Published var passiveIncomeBalance: Double = 0
    @Published var passiveIncomeUpdatedAt: Date = Date()

    // MARK: - Content
    @Published var activeEvents: [GameEvent]

    // MARK: - Counter Session
    @Published var currentCustomer: Customer?
    @Published var customerQueue: [Customer]
    @Published var isBargaining: Bool = false
    private var arrivalTask: Task<Void, Never>?

    // MARK: - Stats
    @Published var totalTransactions: Int
    @Published var acceptedDeals: Int
    @Published var rejectedDeals: Int

    // MARK: - Lifestyle
    @Published var lifestyleItems: [LifestyleItem]
    @Published var lifestyleScore: Int

    // MARK: - Identity
    static let placeholderShopName = "Misafir"
    @Published var shopName: String = GameState.placeholderShopName
    @Published var hasCloudData: Bool = false

    static func normalizedShopName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isPlaceholderShopName(_ raw: String) -> Bool {
        normalizedShopName(raw).caseInsensitiveCompare(placeholderShopName) == .orderedSame
    }

    static func needsShopNameSetup(_ raw: String) -> Bool {
        let normalized = normalizedShopName(raw)
        return normalized.isEmpty || isPlaceholderShopName(normalized)
    }

    // MARK: - History
    @Published var yesterdayCash: Double

    // MARK: - Daily Reward
    @Published var dailyRewardDay: Int       = 0    // son alınan gün (0 = hiç)
    @Published var dailyRewardClaimedAt: Date? = nil // son alım tarihi
    @Published var entryRightsRefreshedAt: Date? = nil
    @Published var profitDayAnchorAt: Date? = nil
    @Published var saveRevision: Int64 = 0
    @Published var cloudSyncStatus: CloudSyncStatus = .idle
    @Published var cloudSyncErrorMessage: String?
    @Published var cloudSyncUpdatedAt: Date?

    static let dailyRewardAmounts: [Int: Double] = [
        1: 5_000,
        3: 15_000,
        5: 35_000,
        7: 50_000
    ]

    static func dailyRewardKind(for day: Int) -> DailyRewardKind {
        switch day {
        case 2:
            return .spinRights(1)
        case 4:
            return .spinRights(2)
        case 6:
            return .spinRights(3)
        default:
            return .cash(dailyRewardAmounts[day] ?? 0)
        }
    }

    static func taxRate(for profit: Double) -> Double {
        guard profit > 0 else { return 0 }
        switch profit {
        case ...1_000_000:
            return 0.10
        case ...5_000_000:
            return 0.18
        case ...10_000_000:
            return 0.25
        default:
            return 0.30
        }
    }

    /// Oyun günü başlangıcı: İstanbul 08:00 (UTC+3)
    static func istanbulGameDayStart(of date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = 8; comps.minute = 0; comps.second = 0
        let boundary = cal.date(from: comps)!
        // 08:00'dan önce isek bir önceki günün 08:00'ına aitiz
        return date < boundary ? cal.date(byAdding: .day, value: -1, to: boundary)! : boundary
    }

    static func isSameGameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        istanbulGameDayStart(of: lhs) == istanbulGameDayStart(of: rhs)
    }

    static func gameDayDelta(from start: Date, to end: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let startDay = istanbulGameDayStart(of: start)
        let endDay = istanbulGameDayStart(of: end)
        return max(0, cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0)
    }

    private var daysSinceLastClaim: Int {
        guard let last = dailyRewardClaimedAt else { return Int.max }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let claimDay = Self.istanbulGameDayStart(of: last)
        let todayDay = Self.istanbulGameDayStart(of: Date())
        return cal.dateComponents([.day], from: claimDay, to: todayDay).day ?? Int.max
    }

    var dailyRewardClaimedToday: Bool { daysSinceLastClaim == 0 }

    var dailyRewardAvailableDay: Int {
        let d = daysSinceLastClaim
        if d == 0 { return dailyRewardDay }            // bugün alındı
        if d == 1 { return min(dailyRewardDay + 1, 7) } // dün alındı → sonraki
        return 1                                       // 2+ gün → sıfır
    }

    func claimDailyReward() {
        syncProfitPeriodsIfNeeded()
        guard !dailyRewardClaimedToday else { return }
        let day = dailyRewardAvailableDay
        switch Self.dailyRewardKind(for: day) {
        case .cash(let reward):
            receiveCash(reward)
            dailyProfit += reward
            weeklyProfit += reward
            totalProfit += reward
        case .spinRights(let count):
            spinRightsRemaining += max(0, count)
        }
        dailyRewardDay = day
        dailyRewardClaimedAt = Date()
        persistChanges()
    }

    func syncEntryRightsIfNeeded(at date: Date = Date()) {
        if let lastRefreshedAt = entryRightsRefreshedAt,
           Self.isSameGameDay(lastRefreshedAt, date) {
            entryRightsRemaining = min(max(entryRightsRemaining, 0), 3)
            return
        }

        entryRightsRemaining = 3
        entryRightsRefreshedAt = date
    }

    var canEnterShop: Bool {
        // Saf getter: yan etki yok. Hak yenileme (syncEntryRightsIfNeeded) her çağrı
        // noktasında (ekran açılışı, scenePhase, promptEntry) zaten açıkça yapılıyor.
        entryRightsRemaining > 0 && !hasOutstandingTax
    }

    var hasOutstandingTax: Bool {
        taxDebt > 0
    }

    var canPayTax: Bool {
        playerCash >= taxDebt && taxDebt > 0
    }

    var canSpinWheel: Bool {
        spinRightsRemaining > 0
    }

    @discardableResult
    func consumeEntryRightAndEnterShop(_ shop: Shop, at date: Date = Date()) -> Bool {
        syncEntryRightsIfNeeded(at: date)
        guard entryRightsRemaining > 0 else { return false }

        entryRightsRemaining -= 1
        entryRightsRefreshedAt = date
        enterShop(shop)
        return true
    }

    func refreshEntryRightsFromAd(at date: Date = Date()) {
        entryRightsRemaining = 3
        entryRightsRefreshedAt = date
        persistChanges()
    }

    func calculateTax(for profit: Double) -> Double {
        let rate = Self.taxRate(for: profit)
        guard rate > 0 else { return 0 }
        return (profit * rate).rounded()
    }

    @discardableResult
    func payTax() -> Bool {
        guard canPayTax else { return false }
        guard spendCash(taxDebt) else { return false }
        taxDebt = 0
        persistChanges()
        return true
    }

    /// Çark hakkını tüketir ve hemen persist eder. Hak başta düşürülür ki animasyon
    /// sırasında uygulama kapatılsa bile "bedava tekrar çevirme" açığı oluşmasın.
    @discardableResult
    func consumeSpinRight() -> Bool {
        guard spinRightsRemaining > 0 else { return false }
        spinRightsRemaining -= 1
        persistChanges()
        return true
    }

    /// Ödülü hesaba işler (hak düşürmez — hak `consumeSpinRight` ile önceden tüketilir).
    func grantWheelReward(_ reward: WheelReward) {
        applyWheelReward(reward, persistsChanges: true)
    }

    func randomWheelReward() -> WheelReward {
        selectWheelReward()
    }

    private func applyWheelReward(_ reward: WheelReward, persistsChanges: Bool) {
        let rewardValue = wheelRewardValue(for: reward)

        switch reward {
        case .tl10k:
            receiveCash(10_000)
        case .tl20k:
            receiveCash(20_000)
        case .tl30k:
            receiveCash(30_000)
        case .tl40k:
            receiveCash(40_000)
        case .tl50k:
            receiveCash(50_000)
        case .spinRights2:
            spinRightsRemaining += 2
        case .usd1000:
            inventory.usd += 1_000
        case .eur1000:
            inventory.eur += 1_000
        case .gram1:
            inventory.gramGold += 1
        case .quarter1:
            inventory.quarterGold += 1
        case .half1:
            inventory.halfGold += 1
        case .full1:
            inventory.fullGold += 1
        }

        dailyProfit += rewardValue
        weeklyProfit += rewardValue
        totalProfit += rewardValue

        if persistsChanges {
            persistChanges()
        }
    }

    private func wheelRewardValue(for reward: WheelReward) -> Double {
        switch reward {
        case .tl10k: return 10_000
        case .tl20k: return 20_000
        case .tl30k: return 30_000
        case .tl40k: return 40_000
        case .tl50k: return 50_000
        case .spinRights2: return 0
        case .usd1000:
            return 1_000 * (rate(for: "USD")?.buyPrice ?? 0)
        case .eur1000:
            return 1_000 * (rate(for: "EUR")?.buyPrice ?? 0)
        case .gram1:
            return rate(for: "gramGold")?.buyPrice ?? 0
        case .quarter1:
            return rate(for: "quarterGold")?.buyPrice ?? 0
        case .half1:
            return rate(for: "halfGold")?.buyPrice ?? 0
        case .full1:
            return rate(for: "fullGold")?.buyPrice ?? 0
        }
    }

    private func selectWheelReward() -> WheelReward {
        let rewards = WheelReward.allCases
        let totalWeight = rewards.reduce(0) { $0 + $1.weight }
        var threshold = Int.random(in: 0..<max(totalWeight, 1))

        for reward in rewards {
            threshold -= reward.weight
            if threshold < 0 {
                return reward
            }
        }

        return rewards[0]
    }

    @discardableResult
    func syncProfitPeriodsIfNeeded(
        at date: Date = Date(),
        persistsChanges: Bool = false,
        syncsCloud: Bool = false
    ) -> Bool {
        if let profitDayAnchorAt {
            let dayDelta = Self.gameDayDelta(from: profitDayAnchorAt, to: date)
            guard dayDelta > 0 else { return false }

            yesterdayCash = playerCash
            for _ in 0..<dayDelta {
                applyDailyTaxIfNeeded()
                currentDay += 1
                dailyProfit = 0
                if currentDay % 7 == 0 { weeklyProfit = 0 }
                if currentDay % 30 == 0 { monthlyRevenue = 0 }
            }
        }

        let didChange = profitDayAnchorAt == nil || !Self.isSameGameDay(profitDayAnchorAt ?? date, date)
        profitDayAnchorAt = date

        if didChange && persistsChanges {
            persistChanges(syncCloud: syncsCloud)
        }

        return didChange
    }

    func retryCloudSync() {
        persistChanges(bumpRevision: false)
    }

    // MARK: - Init

    init() {
        let shops = GameSeedData.allShops
        self.playerCash                  = 1_000_000
        self.inventory                   = GameSeedData.initialInventory
        self.rates                       = GameSeedData.initialRates
        self.ownedShops                  = shops.filter { $0.isOwned }
        self.lockedShops                 = shops.filter { !$0.isOwned }
        let firstShop                    = shops.first(where: { $0.isOwned })
        self.activeShop                  = firstShop
        self.entryRightsRemaining        = 3
        self.spinRightsRemaining         = 0
        self.totalProfit                 = 0
        self.dailyProfit                 = 0
        self.weeklyProfit                = 0
        self.monthlyRevenue              = 0
        self.taxDebt                     = 0
        self.lastTaxChargedDay           = 0
        self.currentDay  = 1
        self.activeEvents = GameSeedData.allEvents
        self.totalTransactions           = 0
        self.acceptedDeals               = 0
        self.rejectedDeals               = 0
        self.lifestyleItems              = GameSeedData.allLifestyleItems
        self.lifestyleScore              = 0
        self.yesterdayCash               = 0
        self.customerQueue               = []
        self.currentCustomer             = nil

        // Uygulama açılışında günlük fiyat güncelleme kontrolü (Supabase'den)
        // Not: Asıl yükleme KuyumcuApp içinde SupabaseSaveService.load() ile yapılır.
        // Müşteri timer'ı CounterView.onAppear'da başlatılır.
    }

    // MARK: - Rate Fetch

    @MainActor
    func fetchRatesIfNeeded() async {
        await SupabaseSaveService.loadRates(into: self)
    }

    // MARK: - Computed Properties

    var totalNetWorth: Double {
        var worth = playerCash
        worth += inventory.gramGold    * (rate(for: "gramGold")?.buyPrice    ?? 4580)
        worth += inventory.quarterGold * (rate(for: "quarterGold")?.buyPrice ?? 10180)
        worth += inventory.halfGold    * (rate(for: "halfGold")?.buyPrice    ?? 20360)
        worth += inventory.fullGold    * (rate(for: "fullGold")?.buyPrice    ?? 40720)
        worth += inventory.usd         * (rate(for: "USD")?.buyPrice         ?? 44.80)
        worth += inventory.eur         * (rate(for: "EUR")?.buyPrice         ?? 48.80)
        return worth
    }

    var passiveIncomeAvailable: Double {
        passiveIncomeAvailable(at: Date())
    }

    var passiveIncomePerSecond: Double {
        ownedShops.reduce(0.0) { total, shop in
            total + (shop.locationType.passiveTick / 10.0)
                * employeeMultiplier(for: shop)
                * eventTrafficMultiplier
        }
    }

    func passiveIncomeAvailable(at date: Date) -> Double {
        let elapsed = max(0, date.timeIntervalSince(passiveIncomeUpdatedAt))
        return passiveIncomeBalance + elapsed * passiveIncomePerSecond
    }

    func settlePassiveIncome(at date: Date = Date()) {
        passiveIncomeBalance = passiveIncomeAvailable(at: date)
        passiveIncomeUpdatedAt = date
    }

    var eventTrafficMultiplier: Double {
        activeEvents.filter { $0.isActive }.reduce(1.0) { $0 * $1.trafficModifier }
    }

    var eventGenerosityMultiplier: Double {
        let multiplier = activeEvents.filter { $0.isActive }.reduce(1.0) { $0 * $1.generosityModifier }
        return min(max(multiplier, 0.7), 1.6)
    }

    var eventVIPMultiplier: Double {
        let multiplier = activeEvents.filter { $0.isActive }.reduce(1.0) { $0 * $1.vipModifier }
        return min(max(multiplier, 0.5), 2.5)
    }

    func employeeMultiplier(for shop: Shop) -> Double {
        1.0 + Double(shop.employeeCount) * 0.05
    }

    func rate(for type: String) -> Rate? {
        rates.first(where: { $0.type == type })
    }

    var activeShopKey: String? {
        activeShop?.key
    }

    @discardableResult
    private func spendCash(_ amount: Double) -> Bool {
        guard amount >= 0, playerCash >= amount else { return false }
        playerCash -= amount
        return true
    }

    private func receiveCash(_ amount: Double) {
        guard amount >= 0 else { return }
        playerCash += amount
    }

    // MARK: - Actions

    func collectPassiveIncome() {
        syncProfitPeriodsIfNeeded()
        let now = Date()
        let income = passiveIncomeAvailable(at: now)
        guard income > 0 else { return }
        receiveCash(income)
        dailyProfit += income
        weeklyProfit += income
        totalProfit += income
        passiveIncomeBalance = 0
        passiveIncomeUpdatedAt = now
        persistChanges()
    }

    func hireEmployee(shopId: UUID) {
        guard let idx = ownedShops.firstIndex(where: { $0.id == shopId }) else { return }
        hireEmployee(at: idx)
    }

    func hireEmployee(shopName: String) {
        guard let idx = ownedShops.firstIndex(where: { $0.name == shopName }) else { return }
        hireEmployee(at: idx)
    }

    private func hireEmployee(at idx: Int) {
        guard ownedShops.indices.contains(idx),
              ownedShops[idx].isOwned,
              ownedShops[idx].employeeCount < ownedShops[idx].employeeCapacity else { return }

        let shopId = ownedShops[idx].id
        let cost = ownedShops[idx].locationType.employeeHireCost
        guard playerCash >= cost else { return }
        settlePassiveIncome()
        guard spendCash(cost) else { return }
        ownedShops[idx].employeeCount += 1
        if activeShop?.id == shopId {
            activeShop = ownedShops[idx]
        }
        persistChanges()
    }

    func advanceDay() {
        yesterdayCash = playerCash
        applyDailyTaxIfNeeded()
        currentDay   += 1
        dailyProfit   = 0
        profitDayAnchorAt = Date()
        isBargaining                 = false
        if currentDay % 7  == 0 { weeklyProfit   = 0 }
        if currentDay % 30 == 0 { monthlyRevenue  = 0 }
        persistChanges()
    }

    // MARK: - Quick Trade (komisyonsuz toptancı)

    func quickTrade(category: ProductCategory, qty: Double, isBuying: Bool) {
        guard qty > 0 else { return }
        syncProfitPeriodsIfNeeded()
        let netWorthBefore = totalNetWorth
        let rateKey: String
        switch category {
        case .goldGram:    rateKey = "gramGold"
        case .goldQuarter: rateKey = "quarterGold"
        case .goldHalf:    rateKey = "halfGold"
        case .goldFull:    rateKey = "fullGold"
        case .currencyUSD: rateKey = "USD"
        case .currencyEUR: rateKey = "EUR"
        case .jewelry:     rateKey = "gramGold"
        }

        let price = isBuying ? (rate(for: rateKey)?.sellPrice ?? 0) : (rate(for: rateKey)?.buyPrice ?? 0)
        let total = price * qty

        if isBuying {
            guard spendCash(total) else { return }
        } else {
            guard hasEnoughInventory(category: category, quantity: qty) else { return }
            receiveCash(total)
        }

        switch category {
        case .goldGram:
            if isBuying { inventory.gramGold += qty } else { inventory.gramGold -= qty }
        case .goldQuarter:
            if isBuying { inventory.quarterGold += qty } else { inventory.quarterGold -= qty }
        case .goldHalf:
            if isBuying { inventory.halfGold += qty } else { inventory.halfGold -= qty }
        case .goldFull:
            if isBuying { inventory.fullGold += qty } else { inventory.fullGold -= qty }
        case .currencyUSD:
            if isBuying { inventory.usd += qty } else { inventory.usd -= qty }
        case .currencyEUR:
            if isBuying { inventory.eur += qty } else { inventory.eur -= qty }
        case .jewelry:
            if isBuying { inventory.gramGold += qty } else { inventory.gramGold -= qty }
        }
        let profitDelta = totalNetWorth - netWorthBefore
        dailyProfit += profitDelta
        weeklyProfit += profitDelta
        totalProfit += profitDelta
        persistChanges()
    }

    // MARK: - Reset Game

    func resetGame() {
        resetLocalProgress(keepsShopName: true, persistsChanges: true, syncsCloud: true)
    }

    func resetLocalProgress(
        keepsShopName: Bool = false,
        persistsChanges: Bool = false,
        syncsCloud: Bool = false
    ) {
        let retainedShopName = shopName
        let retainedRates = rates
        let shops = GameSeedData.allShops
        let first = shops.first(where: { $0.isOwned })
        playerCash                  = 1_000_000
        inventory                   = GameSeedData.initialInventory
        rates                       = retainedRates
        ownedShops                  = shops.filter { $0.isOwned }
        lockedShops                 = shops.filter { !$0.isOwned }
        activeShop                  = first
        shopName = keepsShopName ? retainedShopName : Self.placeholderShopName
        entryRightsRemaining        = 3
        spinRightsRemaining         = 0
        totalProfit                 = 0
        dailyProfit                 = 0
        weeklyProfit                = 0
        monthlyRevenue              = 0
        taxDebt                     = 0
        lastTaxChargedDay           = 0
        currentDay        = 1
        passiveIncomeBalance        = 0
        passiveIncomeUpdatedAt      = Date()
        totalTransactions = 0
        acceptedDeals               = 0
        rejectedDeals               = 0
        lifestyleItems              = GameSeedData.allLifestyleItems
        lifestyleScore              = 0
        yesterdayCash               = 0
        dailyRewardDay              = 0
        dailyRewardClaimedAt        = nil
        entryRightsRefreshedAt      = nil
        profitDayAnchorAt           = nil
        isBargaining                = false
        customerQueue               = []
        currentCustomer             = nil
        if persistsChanges {
            persistChanges(syncCloud: false)
        } else {
            GameSaveService.reset()
        }
        if syncsCloud {
            SupabaseSaveService.enqueueSave(self)
        }
    }

    // MARK: - Transaction Processing

    @discardableResult
    func processAcceptedTransaction(offer: Double, direction: TransactionDirection, items: [RequestItem]) -> Bool {
        guard offer > 0 else { return false }
        syncProfitPeriodsIfNeeded()
        let baseValue = calculateBaseValue(for: items, direction: direction)
        let profit: Double

        switch direction {
        case .customerBuysFromPlayer:
            guard hasEnoughStock(for: items, direction: direction) else { return false }
            profit = offer - baseValue
            receiveCash(offer)
            deductInventory(items: items)

        case .customerSellsToPlayer:
            guard spendCash(offer) else { return false }
            profit = baseValue - offer
            addInventory(items: items)
        }

        dailyProfit     += profit
        weeklyProfit    += profit
        monthlyRevenue  += offer
        totalProfit     += profit
        totalTransactions += 1
        acceptedDeals   += 1
        isBargaining     = false
        advanceCustomer()
        persistChanges()
        return true
    }

    func processRejectedTransaction() {
        totalTransactions += 1
        rejectedDeals     += 1
        isBargaining       = false
        advanceCustomer()
        persistChanges()
    }

    func processBargain() {
        isBargaining = true
        // No save needed – no permanent state change yet
    }

    func processTimerExpired() {
        isBargaining = false
        advanceCustomer()
        persistChanges()
    }

    /// Aktif dükkanı değiştirir. Müşteri kuyruğu yalnızca CounterView görünürken başlatılır.
    func enterShop(_ shop: Shop) {
        activeShop = shop
        persistChanges()
    }

    func advanceCustomer() {
        if !customerQueue.isEmpty {
            customerQueue.removeFirst()
        }
        currentCustomer = customerQueue.first
    }

    func buyShop(_ shop: Shop) {
        guard playerCash >= shop.purchasePrice else { return }
        settlePassiveIncome()
        guard spendCash(shop.purchasePrice) else { return }
        var purchased      = shop
        purchased.isOwned  = true
        lockedShops.removeAll { $0.id == shop.id }
        ownedShops.append(purchased)
        persistChanges()
    }

    func buyLifestyleItem(_ item: LifestyleItem) {
        guard !item.isOwned, spendCash(item.price) else { return }
        if let idx = lifestyleItems.firstIndex(where: { $0.id == item.id }) {
            lifestyleItems[idx].isOwned = true
        }
        recalculateLifestyleScore()
        persistChanges()
    }

    // MARK: - Stock Check

    /// Müşteri oyuncudan satın alıyorsa, envanterde yeterli ürün var mı?
    func hasEnoughStock(for items: [RequestItem], direction: TransactionDirection) -> Bool {
        guard direction == .customerBuysFromPlayer else { return true }
        for (bucket, requiredQuantity) in requiredInventoryBuckets(for: items) {
            if availableQuantity(in: bucket) < requiredQuantity {
                return false
            }
        }
        return true
    }

    func hasEnoughInventory(category: ProductCategory, quantity: Double) -> Bool {
        guard quantity > 0 else { return false }
        switch category {
        case .goldGram:    return inventory.gramGold    >= quantity
        case .goldQuarter: return inventory.quarterGold >= quantity
        case .goldHalf:    return inventory.halfGold    >= quantity
        case .goldFull:    return inventory.fullGold    >= quantity
        case .currencyUSD: return inventory.usd         >= quantity
        case .currencyEUR: return inventory.eur         >= quantity
        case .jewelry:     return inventory.gramGold    >= quantity
        }
    }

    // MARK: - Value Calculation

    func calculateBaseValue(for items: [RequestItem], direction: TransactionDirection) -> Double {
        items.reduce(0.0) { $0 + itemBaseValue(item: $1, direction: direction) }
    }

    func itemBaseValue(item: RequestItem, direction: TransactionDirection) -> Double {
        // For selling to customer → use sell price; for buying from customer → use buy price
        let useSell = direction == .customerBuysFromPlayer
        func pick(_ r: Rate?) -> Double { r.map { useSell ? $0.sellPrice : $0.buyPrice } ?? 0 }

        switch item.productCategory {
        case .goldGram:     return pick(rate(for: "gramGold"))    * item.quantity
        case .goldQuarter:  return pick(rate(for: "quarterGold")) * item.quantity
        case .goldHalf:     return pick(rate(for: "halfGold"))    * item.quantity
        case .goldFull:     return pick(rate(for: "fullGold"))    * item.quantity
        case .currencyUSD:  return pick(rate(for: "USD"))         * item.quantity
        case .currencyEUR:  return pick(rate(for: "EUR"))         * item.quantity
        case .jewelry:      return pick(rate(for: "gramGold"))    * item.quantity
        }
    }

    // MARK: - Acceptance Logic

    /// Returns .accepted / .bargained / .rejected based on offer vs market
    func evaluateOffer(offer: Double, customer: Customer, direction: TransactionDirection, items: [RequestItem]) -> TransactionResult {
        let baseValue = calculateBaseValue(for: items, direction: direction)
        guard baseValue > 0, offer > 0 else { return .rejected }

        let margin    = offer / baseValue
        let tolerance = customer.customerType.marginTolerance
        let genBonus  = customer.generosity * 0.08 * eventGenerosityMultiplier

        switch direction {
        case .customerBuysFromPlayer:
            // Customer pays us. We want margin ≥ 1.0 for profit.
            // Customer accepts up to maxMargin, tolerant types accept more.
            let maxMargin = 1.0 + max(0, tolerance - 1.0) * 0.4 + genBonus
            if margin <= 1.0           { return .accepted }
            if margin <= maxMargin     { return .accepted }
            if margin <= maxMargin * 1.07 && !isBargaining { return .bargained }
            return .rejected

        case .customerSellsToPlayer:
            // We pay the customer. Customer wants margin ≥ 1.0.
            // We want to pay below market. Tolerant types accept lower offers.
            let minMargin = max(0.50, 1.0 - max(0, tolerance - 0.5) * 0.35 - genBonus)
            if margin >= 1.0           { return .accepted }
            if margin >= minMargin     { return .accepted }
            if margin >= minMargin * 0.95 && !isBargaining { return .bargained }
            return .rejected
        }
    }

    // MARK: - Private Helpers

    func startArrivalTimer() {
        arrivalTask?.cancel()
        customerQueue = []
        currentCustomer = nil
        spawnCustomer()
        scheduleNextCustomerArrival()
    }

    func stopArrivalTimer() {
        arrivalTask?.cancel()
    }

    func spawnCustomer() {
        let cap = activeShop?.locationType.queueCapacity ?? 5
        if customerQueue.count >= cap {
            return
        }
        let currentShop = activeShop
        let locationType = currentShop?.locationType ?? .neighborhood
        let newCustomer = CustomerLibrary.generateCustomer(
            for: locationType,
            vipModifier: eventVIPMultiplier,
            shopVIPChance: currentShop?.vipChance ?? 0
        )
        customerQueue.append(newCustomer)
        if currentCustomer == nil {
            currentCustomer = customerQueue.first
        }
    }

    private func scheduleNextCustomerArrival() {
        arrivalTask?.cancel()
        let baseDelay = Double.random(in: 4...8)
        let shopTrafficMultiplier = max(activeShop?.customerTrafficMultiplier ?? 1.0, 0.1)
        let effectiveTraffic = max(shopTrafficMultiplier * eventTrafficMultiplier, 0.1)
        let delay = min(8.0, max(1.75, baseDelay / effectiveTraffic))
        arrivalTask = Task { [weak self] in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.spawnCustomer()
                self.scheduleNextCustomerArrival()
            }
        }
    }

    private func deductInventory(items: [RequestItem]) {
        for (bucket, quantity) in requiredInventoryBuckets(for: items) {
            adjustInventory(bucket: bucket, delta: -quantity)
        }
    }

    private func addInventory(items: [RequestItem]) {
        for item in items {
            adjustInventory(bucket: inventoryBucket(for: item.productCategory), delta: item.quantity)
        }
    }

    private func requiredInventoryBuckets(for items: [RequestItem]) -> [InventoryBucket: Double] {
        items.reduce(into: [:]) { totals, item in
            let bucket = inventoryBucket(for: item.productCategory)
            totals[bucket, default: 0] += item.quantity
        }
    }

    private func inventoryBucket(for category: ProductCategory) -> InventoryBucket {
        switch category {
        case .goldGram, .jewelry: return .gramGold
        case .goldQuarter: return .quarterGold
        case .goldHalf: return .halfGold
        case .goldFull: return .fullGold
        case .currencyUSD: return .usd
        case .currencyEUR: return .eur
        }
    }

    private func availableQuantity(in bucket: InventoryBucket) -> Double {
        switch bucket {
        case .gramGold: return inventory.gramGold
        case .quarterGold: return inventory.quarterGold
        case .halfGold: return inventory.halfGold
        case .fullGold: return inventory.fullGold
        case .usd: return inventory.usd
        case .eur: return inventory.eur
        }
    }

    private func adjustInventory(bucket: InventoryBucket, delta: Double) {
        switch bucket {
        case .gramGold: inventory.gramGold += delta
        case .quarterGold: inventory.quarterGold += delta
        case .halfGold: inventory.halfGold += delta
        case .fullGold: inventory.fullGold += delta
        case .usd: inventory.usd += delta
        case .eur: inventory.eur += delta
        }
    }

    func recalculateLifestyleScore() {
        lifestyleScore = lifestyleItems
            .filter(\.isOwned)
            .reduce(0) { $0 + $1.lifestylePoints }
    }

    private func applyDailyTaxIfNeeded() {
        guard currentDay > lastTaxChargedDay else { return }

        let closedDayProfit = dailyProfit
        let taxAmount = calculateTax(for: closedDayProfit)
        if taxAmount > 0 {
            taxDebt += taxAmount
        }

        lastTaxChargedDay = currentDay
    }

    private func persistChanges(syncCloud: Bool = true, bumpRevision: Bool = true) {
        if bumpRevision {
            saveRevision += 1
        }
        GameSaveService.save(self)
        if syncCloud {
            SupabaseSaveService.enqueueSave(self)
        }
    }
}
