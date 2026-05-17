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
    @Published var passiveIncomeCollectedToday: Bool

    // MARK: - Content
    @Published var activeEvents: [GameEvent]

    // MARK: - Counter Session
    @Published var currentCustomer: Customer?
    @Published var customerQueue: [Customer]
    @Published var isBargaining: Bool = false

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
    @Published var isGuest: Bool = false

    // MARK: - History
    @Published var yesterdayCash: Double
    @Published var previousRatePrices: [String: Double]

    // MARK: - Init

    init() {
        let shops = MockGameData.allShops
        self.playerCash                  = 1_000_000
        self.inventory                   = MockGameData.initialInventory
        self.rates                       = MockGameData.initialRates
        self.ownedShops                  = shops.filter { $0.isOwned }
        self.lockedShops                 = shops.filter { !$0.isOwned }
        let firstShop                    = shops.first(where: { $0.isOwned })
        self.activeShop                  = firstShop
        self.customerSatisfaction        = 50
        self.totalProfit                 = 0
        self.dailyProfit                 = 0
        self.weeklyProfit                = 0
        self.monthlyRevenue              = 0
        self.currentDay                  = 1
        self.passiveIncomeCollectedToday = false
        self.activeEvents                = MockGameData.allEvents
        self.totalTransactions           = 0
        self.acceptedDeals               = 0
        self.rejectedDeals               = 0
        self.lifestyleItems              = MockGameData.allLifestyleItems
        self.lifestyleScore              = 0
        self.trustScore                  = 50
        self.yesterdayCash               = 0
        self.previousRatePrices          = [:]
        let initLocationType             = firstShop?.locationType ?? .neighborhood
        let queue                        = MockGameData.generateCustomerQueue(count: 6, for: initLocationType)
        self.customerQueue               = queue
        self.currentCustomer             = queue.first

        GameSaveService.load(into: self)

        // Uygulama açılışında günlük fiyat güncelleme kontrolü
        Task { await fetchRatesIfNeeded() }
    }

    // MARK: - Rate Fetch

    @MainActor
    func fetchRatesIfNeeded() async {
        guard RateFetchService.shared.shouldFetch() else { return }
        do {
            let fetched = try await RateFetchService.shared.fetchRates()
            updateRates(from: fetched)
        } catch {
            // Ağ hatası → mevcut (mock/kayıtlı) fiyatlar geçerli kalır
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
    }

    // MARK: - Computed Properties

    var totalNetWorth: Double {
        var worth = playerCash
        worth += inventory.gramGold    * (rate(for: "gramGold")?.buyPrice    ?? 4600)
        worth += inventory.quarterGold * (rate(for: "quarterGold")?.buyPrice ?? 10200)
        worth += inventory.halfGold    * (rate(for: "halfGold")?.buyPrice    ?? 20400)
        worth += inventory.fullGold    * (rate(for: "fullGold")?.buyPrice    ?? 40800)
        worth += inventory.usd         * (rate(for: "USD")?.buyPrice         ?? 45)
        worth += inventory.eur         * (rate(for: "EUR")?.buyPrice         ?? 49)
        return worth
    }

    var passiveIncomeAvailable: Double {
        guard !passiveIncomeCollectedToday else { return 0 }
        return ownedShops.reduce(0.0) { sum, shop in
            sum + shop.dailyPassiveBaseIncome * shop.passiveMultiplier * employeeMultiplier(for: shop) * eventTrafficMultiplier
        }
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
        guard !passiveIncomeCollectedToday else { return }
        let income = passiveIncomeAvailable
        playerCash                  += income
        inventory.tryCash           += income
        passiveIncomeCollectedToday  = true
        dailyProfit                 += income
        totalProfit                 += income
        GameSaveService.save(self)
    }

    func hireEmployee(shopId: UUID) {
        guard let idx = ownedShops.firstIndex(where: { $0.id == shopId }),
              ownedShops[idx].isOwned,
              ownedShops[idx].employeeCount < ownedShops[idx].employeeCapacity else { return }
        let cost = ownedShops[idx].locationType.employeeHireCost
        guard playerCash >= cost else { return }
        playerCash -= cost
        inventory.tryCash -= cost
        ownedShops[idx].employeeCount += 1
        GameSaveService.save(self)
    }

    func advanceDay() {
        yesterdayCash                = inventory.tryCash
        previousRatePrices           = Dictionary(uniqueKeysWithValues: rates.map { ($0.type, ($0.buyPrice + $0.sellPrice) / 2.0) })
        currentDay                  += 1
        passiveIncomeCollectedToday  = false
        dailyProfit                  = 0
        isBargaining                 = false
        refillQueue()
        GameSaveService.save(self)
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
    }

    // MARK: - Reset Game

    func resetGame() {
        GameSaveService.reset()
        let shops = MockGameData.allShops
        let first = shops.first(where: { $0.isOwned })
        playerCash                  = 1_000_000
        inventory                   = MockGameData.initialInventory
        rates                       = MockGameData.initialRates
        ownedShops                  = shops.filter { $0.isOwned }
        lockedShops                 = shops.filter { !$0.isOwned }
        activeShop                  = first
        customerSatisfaction        = 50
        totalProfit                 = 0
        dailyProfit                 = 0
        weeklyProfit                = 0
        monthlyRevenue              = 0
        currentDay                  = 1
        passiveIncomeCollectedToday = false
        totalTransactions           = 0
        acceptedDeals               = 0
        rejectedDeals               = 0
        lifestyleItems              = MockGameData.allLifestyleItems
        lifestyleScore              = 0
        trustScore                  = 50
        yesterdayCash               = 0
        previousRatePrices          = [:]
        isBargaining                = false
        let queue = MockGameData.generateCustomerQueue(count: 6, for: first?.locationType ?? .neighborhood)
        customerQueue   = queue
        currentCustomer = queue.first
    }

    func adjustSatisfaction(_ delta: Int) {
        customerSatisfaction = max(0, min(100, customerSatisfaction + delta))
    }

    // MARK: - Transaction Processing

    func processAcceptedTransaction(offer: Double, direction: TransactionDirection, items: [RequestItem]) {
        let baseValue = calculateBaseValue(for: items, direction: direction)
        let profit: Double

        switch direction {
        case .customerBuysFromPlayer:
            profit = offer - baseValue
            playerCash        += offer
            inventory.tryCash += offer
            deductInventory(items: items)

        case .customerSellsToPlayer:
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
    }

    func processRejectedTransaction() {
        adjustSatisfaction(-1)
        trustScore = max(0, trustScore - 1.0)
        totalTransactions += 1
        rejectedDeals     += 1
        isBargaining       = false
        advanceCustomer()
        GameSaveService.save(self)
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
    }

    /// Aktif dükkanı değiştirir, o dükkanın lokasyonuna göre müşteri kuyruğu oluşturur.
    func enterShop(_ shop: Shop) {
        activeShop = shop
        refillQueue()
        GameSaveService.save(self)
    }

    func advanceCustomer() {
        if !customerQueue.isEmpty {
            customerQueue.removeFirst()
        }
        if customerQueue.count < 4 {
            let locationType = activeShop?.locationType ?? .neighborhood
            customerQueue.append(contentsOf: MockGameData.generateCustomerQueue(count: 2, for: locationType))
        }
        currentCustomer = customerQueue.first
    }

    func buyShop(_ shop: Shop) {
        guard playerCash >= shop.purchasePrice else { return }
        playerCash        -= shop.purchasePrice
        inventory.tryCash -= shop.purchasePrice
        var purchased      = shop
        purchased.isOwned  = true
        lockedShops.removeAll { $0.id == shop.id }
        ownedShops.append(purchased)
        GameSaveService.save(self)
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
    }

    // MARK: - Stock Check

    /// Müşteri oyuncudan satın alıyorsa, envanterde yeterli ürün var mı?
    func hasEnoughStock(for items: [RequestItem], direction: TransactionDirection) -> Bool {
        guard direction == .customerBuysFromPlayer else { return true }
        for item in items {
            switch item.productCategory {
            case .goldGram:    if inventory.gramGold    < item.quantity { return false }
            case .goldQuarter: if inventory.quarterGold < item.quantity { return false }
            case .goldHalf:    if inventory.halfGold    < item.quantity { return false }
            case .goldFull:    if inventory.fullGold    < item.quantity { return false }
            case .currencyUSD: if inventory.usd         < item.quantity { return false }
            case .currencyEUR: if inventory.eur         < item.quantity { return false }
            case .jewelry:     if inventory.gramGold    < item.quantity { return false }
            }
        }
        return true
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

    private func refillQueue() {
        let locationType = activeShop?.locationType ?? .neighborhood
        customerQueue = MockGameData.generateCustomerQueue(count: 6, for: locationType)
        currentCustomer = customerQueue.first
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
