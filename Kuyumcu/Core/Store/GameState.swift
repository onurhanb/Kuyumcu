import Foundation
import Combine

class GameState: ObservableObject {

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
    @Published var customerSatisfaction: Int
    @Published var totalProfit: Double
    @Published var dailyProfit: Double
    @Published var weeklyProfit: Double
    @Published var monthlyRevenue: Double
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

    // MARK: - Reputation
    @Published var trustScore: Double

    // MARK: - Identity
    @Published var shopName: String = "Misafir"

    // MARK: - History
    @Published var yesterdayCash: Double

    // MARK: - Daily Reward
    @Published var dailyRewardDay: Int       = 0    // son alınan gün (0 = hiç)
    @Published var dailyRewardClaimedAt: Date? = nil // son alım tarihi

    static let dailyRewardAmounts: [Int: Double] = [
        1: 5_000, 2: 10_000, 3: 15_000, 4: 20_000,
        5: 25_000, 6: 30_000, 7: 100_000
    ]

    /// Oyun günü başlangıcı: İstanbul 08:00 (UTC+3)
    private static func istanbulGameDayStart(of date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = 8; comps.minute = 0; comps.second = 0
        let boundary = cal.date(from: comps)!
        // 08:00'dan önce isek bir önceki günün 08:00'ına aitiz
        return date < boundary ? cal.date(byAdding: .day, value: -1, to: boundary)! : boundary
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
        guard !dailyRewardClaimedToday else { return }
        let day    = dailyRewardAvailableDay
        let reward = Self.dailyRewardAmounts[day] ?? 0
        playerCash           += reward
        dailyProfit          += reward
        dailyRewardDay        = day
        dailyRewardClaimedAt  = Date()
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
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
        self.customerSatisfaction        = 50
        self.totalProfit                 = 0
        self.dailyProfit                 = 0
        self.weeklyProfit                = 0
        self.monthlyRevenue              = 0
        self.currentDay  = 1
        self.activeEvents = GameSeedData.allEvents
        self.totalTransactions           = 0
        self.acceptedDeals               = 0
        self.rejectedDeals               = 0
        self.lifestyleItems              = GameSeedData.allLifestyleItems
        self.lifestyleScore              = 0
        self.trustScore                  = 50
        self.yesterdayCash               = 0
        self.customerQueue               = []
        self.currentCustomer             = nil

        // Uygulama açılışında günlük fiyat güncelleme kontrolü (Supabase'den)
        // Not: Asıl yükleme KuyumcuApp içinde SupabaseSaveService.load() ile yapılır.

        startArrivalTimer()
    }

    // MARK: - Rate Fetch

    @MainActor
    func fetchRatesIfNeeded() async {
        guard RateFetchService.shared.shouldFetch(currentSourceDate: rates.first?.sourceDate) else { return }
        do {
            let fetched = try await RateFetchService.shared.fetchRates()
            updateRates(from: fetched)
        } catch {
            // Ağ hatası → mevcut (kayıtlı/kayıtlı) fiyatlar geçerli kalır
        }
    }

    @MainActor
    func updateRates(from fetched: FetchedRates) {
        let src  = fetched.sourceName
        let date = fetched.dateString

        func apply(_ type: String, buy: Double, sell: Double) {
            guard let i = rates.firstIndex(where: { $0.type == type }) else { return }
            rates[i].buyPrice   = buy
            rates[i].sellPrice  = sell
            rates[i].sourceName = src
            rates[i].sourceDate = date
        }

        // Genelpara: alis = piyasanın alış (bizim satış), satis = piyasanın satış (bizim alış)
        // Kuyumcu perspektifinden:
        //   buyPrice  = müşteriden aldığımız fiyat → piyasanın alis fiyatı
        //   sellPrice = müşteriye sattığımız fiyat → piyasanın satis fiyatı
        apply("gramGold",    buy: fetched.gramGoldTRY,    sell: fetched.gramGoldSell)
        apply("quarterGold", buy: fetched.quarterGoldTRY, sell: fetched.quarterGoldSell)
        apply("halfGold",    buy: fetched.halfGoldTRY,    sell: fetched.halfGoldSell)
        apply("fullGold",    buy: fetched.fullGoldTRY,    sell: fetched.fullGoldSell)
        apply("USD",         buy: fetched.usdTRY,         sell: fetched.usdSell)
        apply("EUR",         buy: fetched.eurTRY,         sell: fetched.eurSell)

        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
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

    func employeeMultiplier(for shop: Shop) -> Double {
        1.0 + Double(shop.employeeCount) * 0.05
    }

    func rate(for type: String) -> Rate? {
        rates.first(where: { $0.type == type })
    }

    // MARK: - Actions

    func collectPassiveIncome() {
        let now = Date()
        let income = passiveIncomeAvailable(at: now)
        guard income > 0 else { return }
        playerCash        += income
        inventory.tryCash += income
        dailyProfit       += income
        totalProfit       += income
        passiveIncomeBalance = 0
        passiveIncomeUpdatedAt = now
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    func hireEmployee(shopId: UUID) {
        guard let idx = ownedShops.firstIndex(where: { $0.id == shopId }),
              ownedShops[idx].isOwned,
              ownedShops[idx].employeeCount < ownedShops[idx].employeeCapacity else { return }
        let cost = ownedShops[idx].locationType.employeeHireCost
        guard playerCash >= cost else { return }
        settlePassiveIncome()
        playerCash -= cost
        inventory.tryCash -= cost
        ownedShops[idx].employeeCount += 1
        if activeShop?.id == shopId {
            activeShop = ownedShops[idx]
        }
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    func advanceDay() {
        yesterdayCash = inventory.tryCash
        currentDay   += 1
        dailyProfit   = 0
        isBargaining                 = false
        if currentDay % 7  == 0 { weeklyProfit   = 0 }
        if currentDay % 30 == 0 { monthlyRevenue  = 0 }
        startArrivalTimer()
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    // MARK: - Quick Trade (komisyonsuz toptancı)

    func quickTrade(category: ProductCategory, qty: Double, isBuying: Bool) {
        guard qty > 0 else { return }
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
            guard playerCash >= total else { return }
            playerCash        -= total
            inventory.tryCash -= total
        } else {
            guard hasEnoughInventory(category: category, quantity: qty) else { return }
            playerCash        += total
            inventory.tryCash += total
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
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
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
        shopName = keepsShopName ? retainedShopName : "Misafir"
        customerSatisfaction        = 50
        totalProfit                 = 0
        dailyProfit                 = 0
        weeklyProfit                = 0
        monthlyRevenue              = 0
        currentDay        = 1
        passiveIncomeBalance        = 0
        passiveIncomeUpdatedAt      = Date()
        totalTransactions = 0
        acceptedDeals               = 0
        rejectedDeals               = 0
        lifestyleItems              = GameSeedData.allLifestyleItems
        lifestyleScore              = 0
        trustScore                  = 50
        yesterdayCash               = 0
        dailyRewardDay              = 0
        dailyRewardClaimedAt        = nil
        isBargaining                = false
        customerQueue               = []
        currentCustomer             = nil
        if persistsChanges {
            GameSaveService.save(self)
        } else {
            GameSaveService.reset()
        }
        startArrivalTimer()
        if syncsCloud {
            Task { await SupabaseSaveService.save(self) }
        }
    }

    func adjustSatisfaction(_ delta: Int) {
        customerSatisfaction = max(0, min(100, customerSatisfaction + delta))
    }

    // MARK: - Transaction Processing

    @discardableResult
    func processAcceptedTransaction(offer: Double, direction: TransactionDirection, items: [RequestItem]) -> Bool {
        guard offer > 0 else { return false }
        let baseValue = calculateBaseValue(for: items, direction: direction)
        let profit: Double

        switch direction {
        case .customerBuysFromPlayer:
            guard hasEnoughStock(for: items, direction: direction) else { return false }
            profit = offer - baseValue
            playerCash        += offer
            inventory.tryCash += offer
            deductInventory(items: items)

        case .customerSellsToPlayer:
            guard playerCash >= offer else { return false }
            profit = baseValue - offer
            playerCash        -= offer
            inventory.tryCash -= offer
            addInventory(items: items)
        }

        dailyProfit     += profit
        weeklyProfit    += profit
        monthlyRevenue  += offer
        totalProfit     += profit
        totalTransactions += 1
        acceptedDeals   += 1
        isBargaining     = false
        adjustSatisfaction(3)
        trustScore = min(100, trustScore + 0.5)
        advanceCustomer()
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
        return true
    }

    func processRejectedTransaction() {
        adjustSatisfaction(-1)
        trustScore = max(0, trustScore - 1.0)
        totalTransactions += 1
        rejectedDeals     += 1
        isBargaining       = false
        advanceCustomer()
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    func processBargain() {
        isBargaining = true
        adjustSatisfaction(-1)
        // No save needed – no permanent state change yet
    }

    func processTimerExpired() {
        adjustSatisfaction(-1)
        isBargaining = false
        advanceCustomer()
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    /// Aktif dükkanı değiştirir, o dükkanın lokasyonuna göre müşteri kuyruğu oluşturur.
    func enterShop(_ shop: Shop) {
        activeShop = shop
        startArrivalTimer()
        Task { await SupabaseSaveService.save(self) }
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
        playerCash        -= shop.purchasePrice
        inventory.tryCash -= shop.purchasePrice
        var purchased      = shop
        purchased.isOwned  = true
        lockedShops.removeAll { $0.id == shop.id }
        ownedShops.append(purchased)
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    func buyLifestyleItem(_ item: LifestyleItem) {
        guard !item.isOwned, playerCash >= item.price else { return }
        playerCash        -= item.price
        inventory.tryCash -= item.price
        if let idx = lifestyleItems.firstIndex(where: { $0.id == item.id }) {
            lifestyleItems[idx].isOwned = true
        }
        lifestyleScore += item.lifestylePoints
        GameSaveService.save(self)
        Task { await SupabaseSaveService.save(self) }
    }

    // MARK: - Stock Check

    /// Müşteri oyuncudan satın alıyorsa, envanterde yeterli ürün var mı?
    func hasEnoughStock(for items: [RequestItem], direction: TransactionDirection) -> Bool {
        guard direction == .customerBuysFromPlayer else { return true }
        for item in items {
            if !hasEnoughInventory(category: item.productCategory, quantity: item.quantity) { return false }
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
        let genBonus  = customer.generosity * 0.08

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

    func spawnCustomer() {
        let cap = activeShop?.locationType.queueCapacity ?? 5
        if customerQueue.count >= cap {
            trustScore = max(0, trustScore - 5)
            return
        }
        let locationType = activeShop?.locationType ?? .neighborhood
        let newCustomer = CustomerLibrary.generateCustomer(for: locationType)
        customerQueue.append(newCustomer)
        if currentCustomer == nil {
            currentCustomer = customerQueue.first
        }
    }

    private func scheduleNextCustomerArrival() {
        arrivalTask?.cancel()
        let delay = Double.random(in: 4...8)
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
        for item in items {
            switch item.productCategory {
            case .goldGram:    inventory.gramGold    -= item.quantity
            case .goldQuarter: inventory.quarterGold -= item.quantity
            case .goldHalf:    inventory.halfGold    -= item.quantity
            case .goldFull:    inventory.fullGold    -= item.quantity
            case .currencyUSD: inventory.usd         -= item.quantity
            case .currencyEUR: inventory.eur         -= item.quantity
            case .jewelry:     inventory.gramGold    -= item.quantity
            }
        }
    }

    private func addInventory(items: [RequestItem]) {
        for item in items {
            switch item.productCategory {
            case .goldGram:    inventory.gramGold    += item.quantity
            case .goldQuarter: inventory.quarterGold += item.quantity
            case .goldHalf:    inventory.halfGold    += item.quantity
            case .goldFull:    inventory.fullGold    += item.quantity
            case .currencyUSD: inventory.usd         += item.quantity
            case .currencyEUR: inventory.eur         += item.quantity
            case .jewelry:     inventory.gramGold    += item.quantity
            }
        }
    }
}
