import Foundation
import Supabase

// MARK: - Database Row Types
// snake_case → Supabase sütun adlarıyla birebir eşleşir

struct PlayerStatsRow: Codable {
    var userId: UUID
    var shopName: String
    var playerCash: Double
    var inventoryTry: Double
    var inventoryUsd: Double
    var inventoryEur: Double
    var inventoryGram: Double
    var inventoryQuarter: Double
    var inventoryHalf: Double
    var inventoryFull: Double
    var customerSatisfaction: Int
    var totalProfit: Double
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
    var currentDay: Int
    var passiveIncomeCollectedToday: Bool
    var totalTransactions: Int
    var acceptedDeals: Int
    var rejectedDeals: Int
    var trustScore: Double
    var lifestyleScore: Int
    var yesterdayCash: Double
    var dailyRewardDay: Int
    var dailyRewardClaimedAt: String?  // ISO8601

    enum CodingKeys: String, CodingKey {
        case userId                     = "user_id"
        case shopName                   = "shop_name"
        case playerCash                 = "player_cash"
        case inventoryTry               = "inventory_try"
        case inventoryUsd               = "inventory_usd"
        case inventoryEur               = "inventory_eur"
        case inventoryGram              = "inventory_gram"
        case inventoryQuarter           = "inventory_quarter"
        case inventoryHalf              = "inventory_half"
        case inventoryFull              = "inventory_full"
        case customerSatisfaction       = "customer_satisfaction"
        case totalProfit                = "total_profit"
        case dailyProfit                = "daily_profit"
        case weeklyProfit               = "weekly_profit"
        case monthlyRevenue             = "monthly_revenue"
        case currentDay                 = "current_day"
        case passiveIncomeCollectedToday = "passive_income_collected_today"
        case totalTransactions          = "total_transactions"
        case acceptedDeals              = "accepted_deals"
        case rejectedDeals              = "rejected_deals"
        case trustScore                 = "trust_score"
        case lifestyleScore             = "lifestyle_score"
        case yesterdayCash              = "yesterday_cash"
        case dailyRewardDay             = "daily_reward_day"
        case dailyRewardClaimedAt       = "daily_reward_claimed_at"
    }

    init(from state: GameState, userId: UUID) {
        self.userId                      = userId
        self.shopName                    = state.shopName
        self.playerCash                  = state.playerCash
        self.inventoryTry                = state.inventory.tryCash
        self.inventoryUsd                = state.inventory.usd
        self.inventoryEur                = state.inventory.eur
        self.inventoryGram               = state.inventory.gramGold
        self.inventoryQuarter            = state.inventory.quarterGold
        self.inventoryHalf               = state.inventory.halfGold
        self.inventoryFull               = state.inventory.fullGold
        self.customerSatisfaction        = state.customerSatisfaction
        self.totalProfit                 = state.totalProfit
        self.dailyProfit                 = state.dailyProfit
        self.weeklyProfit                = state.weeklyProfit
        self.monthlyRevenue              = state.monthlyRevenue
        self.currentDay                  = state.currentDay
        self.passiveIncomeCollectedToday = state.passiveIncomeCollectedToday
        self.totalTransactions           = state.totalTransactions
        self.acceptedDeals               = state.acceptedDeals
        self.rejectedDeals               = state.rejectedDeals
        self.trustScore                  = state.trustScore
        self.lifestyleScore              = state.lifestyleScore
        self.yesterdayCash               = state.yesterdayCash
        let isoFmt = ISO8601DateFormatter()
        self.dailyRewardDay              = state.dailyRewardDay
        self.dailyRewardClaimedAt        = state.dailyRewardClaimedAt.map { isoFmt.string(from: $0) }
    }
}

struct OwnedShopRow: Codable {
    var userId: UUID
    var shopName: String
    var employeeCount: Int

    enum CodingKeys: String, CodingKey {
        case userId        = "user_id"
        case shopName      = "shop_name"
        case employeeCount = "employee_count"
    }
}

struct LifestyleItemRow: Codable {
    var userId: UUID
    var itemName: String

    enum CodingKeys: String, CodingKey {
        case userId   = "user_id"
        case itemName = "item_name"
    }
}

struct GoldRatesRow: Codable {
    var gramBuy:          Double
    var gramSell:         Double
    var gramChangeDir:    Int
    var quarterBuy:       Double
    var quarterSell:      Double
    var quarterChangeDir: Int
    var halfBuy:          Double
    var halfSell:         Double
    var halfChangeDir:    Int
    var fullBuy:          Double
    var fullSell:         Double
    var fullChangeDir:    Int
    var usdBuy:           Double
    var usdSell:          Double
    var usdChangeDir:     Int
    var eurBuy:           Double
    var eurSell:          Double
    var eurChangeDir:     Int
    var sourceName:       String
    var fetchedAt:        String

    enum CodingKeys: String, CodingKey {
        case gramBuy          = "gram_buy"
        case gramSell         = "gram_sell"
        case gramChangeDir    = "gram_change_dir"
        case quarterBuy       = "quarter_buy"
        case quarterSell      = "quarter_sell"
        case quarterChangeDir = "quarter_change_dir"
        case halfBuy          = "half_buy"
        case halfSell         = "half_sell"
        case halfChangeDir    = "half_change_dir"
        case fullBuy          = "full_buy"
        case fullSell         = "full_sell"
        case fullChangeDir    = "full_change_dir"
        case usdBuy           = "usd_buy"
        case usdSell          = "usd_sell"
        case usdChangeDir     = "usd_change_dir"
        case eurBuy           = "eur_buy"
        case eurSell          = "eur_sell"
        case eurChangeDir     = "eur_change_dir"
        case sourceName       = "source_name"
        case fetchedAt        = "fetched_at"
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: Codable {
    var userId:          UUID
    var shopName:        String
    var playerCash:      Double
    var inventoryGram:   Double
    var inventoryQuarter: Double
    var inventoryHalf:   Double
    var inventoryFull:   Double
    var inventoryUsd:    Double
    var inventoryEur:    Double
    var dailyProfit:     Double
    var weeklyProfit:    Double
    var monthlyRevenue:  Double
    var totalProfit:     Double
    var lifestyleScore:  Int

    enum CodingKeys: String, CodingKey {
        case userId          = "user_id"
        case shopName        = "shop_name"
        case playerCash      = "player_cash"
        case inventoryGram   = "inventory_gram"
        case inventoryQuarter = "inventory_quarter"
        case inventoryHalf   = "inventory_half"
        case inventoryFull   = "inventory_full"
        case inventoryUsd    = "inventory_usd"
        case inventoryEur    = "inventory_eur"
        case dailyProfit     = "daily_profit"
        case weeklyProfit    = "weekly_profit"
        case monthlyRevenue  = "monthly_revenue"
        case totalProfit     = "total_profit"
        case lifestyleScore  = "lifestyle_score"
    }
}

// MARK: - Event Row (game_events tablosu)

struct EventRow: Codable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var accentColor: String
    var trafficModifier: Double
    var generosityModifier: Double
    var vipModifier: Double
    var isActive: Bool
    var endsAt: String?         // ISO8601 — opsiyonel bitiş tarihi

    enum CodingKeys: String, CodingKey {
        case id                 = "id"
        case name               = "name"
        case description        = "description"
        case icon               = "icon"
        case accentColor        = "accent_color"
        case trafficModifier    = "traffic_modifier"
        case generosityModifier = "generosity_modifier"
        case vipModifier        = "vip_modifier"
        case isActive           = "is_active"
        case endsAt             = "ends_at"
    }
}

// MARK: - Supabase Save Service

class SupabaseSaveService {

    // MARK: - Save

    static func save(_ state: GameState) async {
        guard let userId = AuthService.shared.userId else { return }

        async let statsTask: Void     = saveStats(state, userId: userId)
        async let shopsTask: Void     = saveShops(state, userId: userId)
        async let lifestyleTask: Void = saveLifestyle(state, userId: userId)

        _ = await (statsTask, shopsTask, lifestyleTask)
    }

    private static func saveStats(_ state: GameState, userId: UUID) async {
        let row = PlayerStatsRow(from: state, userId: userId)
        do {
            try await supabase
                .from("player_stats")
                .upsert(row)
                .execute()
        } catch {
            print("[SupabaseSave] player_stats hata:", error.localizedDescription)
        }
    }

    private static func saveShops(_ state: GameState, userId: UUID) async {
        let rows = state.ownedShops.map {
            OwnedShopRow(userId: userId, shopName: $0.name, employeeCount: $0.employeeCount)
        }
        do {
            // Mevcut kayıtları sil, yenilerini yaz
            try await supabase
                .from("owned_shops")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            if !rows.isEmpty {
                try await supabase
                    .from("owned_shops")
                    .insert(rows)
                    .execute()
            }
        } catch {
            print("[SupabaseSave] owned_shops hata:", error.localizedDescription)
        }
    }

    private static func saveLifestyle(_ state: GameState, userId: UUID) async {
        let ownedNames = state.lifestyleItems.filter { $0.isOwned }.map { $0.name }
        let rows = ownedNames.map { LifestyleItemRow(userId: userId, itemName: $0) }
        do {
            try await supabase
                .from("lifestyle_items")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            if !rows.isEmpty {
                try await supabase
                    .from("lifestyle_items")
                    .insert(rows)
                    .execute()
            }
        } catch {
            print("[SupabaseSave] lifestyle_items hata:", error.localizedDescription)
        }
    }

    // MARK: - Load

    @MainActor
    static func load(into state: GameState) async {
        guard let userId = AuthService.shared.userId else { return }

        async let statsResult     = fetchStats(userId: userId)
        async let shopsResult     = fetchShops(userId: userId)
        async let lifestyleResult = fetchLifestyle(userId: userId)

        let (stats, shops, lifestyle) = await (statsResult, shopsResult, lifestyleResult)

        if let stats {
            applyStats(stats, to: state)
        }
        if let shops {
            applyShops(shops, to: state)
        }
        if let lifestyle {
            applyLifestyle(lifestyle, to: state)
        }
    }

    private static func fetchStats(userId: UUID) async -> PlayerStatsRow? {
        do {
            let row: PlayerStatsRow = try await supabase
                .from("player_stats")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return row
        } catch {
            // Kayıt henüz yok (yeni kullanıcı) → nil döner, defaults kullanılır
            return nil
        }
    }

    private static func fetchShops(userId: UUID) async -> [OwnedShopRow]? {
        do {
            let rows: [OwnedShopRow] = try await supabase
                .from("owned_shops")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return rows
        } catch {
            return nil
        }
    }

    private static func fetchLifestyle(userId: UUID) async -> [LifestyleItemRow]? {
        do {
            let rows: [LifestyleItemRow] = try await supabase
                .from("lifestyle_items")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return rows
        } catch {
            return nil
        }
    }

    // MARK: - Apply Fetched Data

    private static func applyStats(_ row: PlayerStatsRow, to state: GameState) {
        state.shopName                    = row.shopName
        state.playerCash                  = row.playerCash
        state.inventory.tryCash           = row.inventoryTry
        state.inventory.usd               = row.inventoryUsd
        state.inventory.eur               = row.inventoryEur
        state.inventory.gramGold          = row.inventoryGram
        state.inventory.quarterGold       = row.inventoryQuarter
        state.inventory.halfGold          = row.inventoryHalf
        state.inventory.fullGold          = row.inventoryFull
        state.customerSatisfaction        = row.customerSatisfaction
        state.totalProfit                 = row.totalProfit
        state.dailyProfit                 = row.dailyProfit
        state.weeklyProfit                = row.weeklyProfit
        state.monthlyRevenue              = row.monthlyRevenue
        state.currentDay                  = row.currentDay
        state.passiveIncomeCollectedToday = row.passiveIncomeCollectedToday
        state.totalTransactions           = row.totalTransactions
        state.acceptedDeals               = row.acceptedDeals
        state.rejectedDeals               = row.rejectedDeals
        state.trustScore                  = row.trustScore
        state.lifestyleScore              = row.lifestyleScore
        state.yesterdayCash               = row.yesterdayCash

        // Günlük ödül: Supabase verisini ancak yerel veriden daha güncel/eşit ise uygula.
        // Uygulama kapanırken async save tamamlanmamış olabilir; o durumda
        // GameSaveService (UserDefaults) yedeği daha doğrudur.
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let supabaseClaimedAt = row.dailyRewardClaimedAt.flatMap { isoFmt.date(from: $0) }
        if let supabaseDate = supabaseClaimedAt {
            // Supabase'de tarih var — daha yeni ya da eşit ise kullan
            if state.dailyRewardClaimedAt == nil || supabaseDate >= state.dailyRewardClaimedAt! {
                state.dailyRewardDay       = row.dailyRewardDay
                state.dailyRewardClaimedAt = supabaseDate
            }
            // else: yerel veri daha yeni — dokunma
        } else {
            // Supabase'de tarih yok (save tamamlanmamış) — yerel veri varsa dokunma
            if state.dailyRewardClaimedAt == nil {
                state.dailyRewardDay = row.dailyRewardDay
            }
        }
    }

    private static func applyShops(_ rows: [OwnedShopRow], to state: GameState) {
        guard !rows.isEmpty else { return }
        let allShops = MockGameData.allShops
        let ownedNames = Set(rows.map { $0.shopName })
        // Çalışan sayısını Supabase'den gelen değerle güncelle
        let employeeMap = Dictionary(uniqueKeysWithValues: rows.map { ($0.shopName, $0.employeeCount) })

        state.ownedShops = allShops
            .filter { ownedNames.contains($0.name) }
            .map { shop in
                var s = shop
                s.isOwned = true
                s.employeeCount = employeeMap[shop.name] ?? shop.employeeCount
                return s
            }
        state.lockedShops = allShops.filter { !ownedNames.contains($0.name) }
        state.activeShop  = state.ownedShops.first
    }

    private static func applyLifestyle(_ rows: [LifestyleItemRow], to state: GameState) {
        let ownedNames = Set(rows.map { $0.itemName })
        for i in state.lifestyleItems.indices {
            state.lifestyleItems[i].isOwned = ownedNames.contains(state.lifestyleItems[i].name)
        }
    }

    // MARK: - Rates (Edge Function çıktısından)

    static func loadRates(into state: GameState) async {
        do {
            let row: GoldRatesRow = try await supabase
                .from("gold_rates")
                .select()
                .eq("id", value: 1)
                .single()
                .execute()
                .value

            func apply(_ type: String, buy: Double, sell: Double, changeDir: Int) {
                guard let i = state.rates.firstIndex(where: { $0.type == type }) else { return }
                state.rates[i].buyPrice   = buy
                state.rates[i].sellPrice  = sell
                state.rates[i].changeDir  = changeDir
                state.rates[i].sourceName = row.sourceName
                state.rates[i].sourceDate = row.fetchedAt
            }

            await MainActor.run {
                apply("gramGold",    buy: row.gramBuy,    sell: row.gramSell,    changeDir: row.gramChangeDir)
                apply("quarterGold", buy: row.quarterBuy, sell: row.quarterSell, changeDir: row.quarterChangeDir)
                apply("halfGold",    buy: row.halfBuy,    sell: row.halfSell,    changeDir: row.halfChangeDir)
                apply("fullGold",    buy: row.fullBuy,    sell: row.fullSell,    changeDir: row.fullChangeDir)
                apply("USD",         buy: row.usdBuy,     sell: row.usdSell,     changeDir: row.usdChangeDir)
                apply("EUR",         buy: row.eurBuy,     sell: row.eurSell,     changeDir: row.eurChangeDir)
            }
        } catch {
            print("[SupabaseSave] gold_rates hata:", error.localizedDescription)
        }
    }

    // MARK: - Events (game_events tablosu)

    static func loadEvents(into state: GameState) async {
        do {
            let rows: [EventRow] = try await supabase
                .from("game_events")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value

            let isoFmt = ISO8601DateFormatter()
            isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let events = rows.map { row in
                GameEvent(
                    id: row.id,
                    name: row.name,
                    description: row.description,
                    icon: row.icon,
                    accentColorName: row.accentColor,
                    trafficModifier: row.trafficModifier,
                    generosityModifier: row.generosityModifier,
                    vipModifier: row.vipModifier,
                    isActive: row.isActive,
                    endsAt: row.endsAt.flatMap { isoFmt.date(from: $0) }
                )
            }
            await MainActor.run { state.activeEvents = events }
        } catch {
            print("[SupabaseSave] game_events hata:", error.localizedDescription)
        }
    }

    // MARK: - Leaderboard

    static func fetchLeaderboard(currentUserId: UUID, rates: [Rate]) async -> [LeaderboardEntry] {
        do {
            let rows: [LeaderboardRow] = try await supabase
                .from("player_stats")
                .select("user_id, shop_name, player_cash, inventory_gram, inventory_quarter, inventory_half, inventory_full, inventory_usd, inventory_eur, daily_profit, weekly_profit, monthly_revenue, total_profit, lifestyle_score")
                .neq("user_id", value: currentUserId.uuidString)
                .order("total_profit", ascending: false)
                .limit(9)
                .execute()
                .value

            func price(_ type: String) -> Double {
                rates.first(where: { $0.type == type })?.buyPrice ?? 0
            }

            return rows.map { row in
                let netWorth = row.playerCash
                    + row.inventoryGram    * price("gramGold")
                    + row.inventoryQuarter * price("quarterGold")
                    + row.inventoryHalf    * price("halfGold")
                    + row.inventoryFull    * price("fullGold")
                    + row.inventoryUsd     * price("USD")
                    + row.inventoryEur     * price("EUR")

                return LeaderboardEntry(
                    id:              row.userId,
                    playerName:      row.shopName,
                    dailyProfit:     row.dailyProfit,
                    weeklyProfit:    row.weeklyProfit,
                    monthlyRevenue:  row.monthlyRevenue,
                    netWorth:        netWorth,
                    cashBalance:     row.playerCash,
                    lifestylePoints: row.lifestyleScore,
                    isPlayer:        false
                )
            }
        } catch {
            print("[SupabaseSave] leaderboard hata:", error.localizedDescription)
            return []
        }
    }
}
