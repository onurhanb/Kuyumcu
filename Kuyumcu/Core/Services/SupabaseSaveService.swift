import Foundation
import Supabase

// MARK: - Database Row Types

struct PlayerStatsRow: Codable {
    var userId: UUID
    var shopName: String
    var activeShopKey: String?
    var playerCash: Double
    var inventoryUsd: Double
    var inventoryEur: Double
    var inventoryGram: Double
    var inventoryQuarter: Double
    var inventoryHalf: Double
    var inventoryFull: Double
    var entryRightsRemaining: Int
    var spinRightsRemaining: Int
    var totalProfit: Double
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
    var taxDebt: Double
    var lastTaxChargedDay: Int
    var currentDay: Int
    var passiveIncomeBalance: Double?
    var passiveIncomeUpdatedAt: String?
    var totalTransactions: Int
    var acceptedDeals: Int
    var rejectedDeals: Int
    var lifestyleScore: Int
    var yesterdayCash: Double
    var dailyRewardDay: Int
    var dailyRewardClaimedAt: String?
    var entryRightsRefreshedAt: String?
    var profitDayAnchorAt: String?
    var saveRevision: Int64

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case shopName = "shop_name"
        case activeShopKey = "active_shop_key"
        case playerCash = "player_cash"
        case inventoryUsd = "inventory_usd"
        case inventoryEur = "inventory_eur"
        case inventoryGram = "inventory_gram"
        case inventoryQuarter = "inventory_quarter"
        case inventoryHalf = "inventory_half"
        case inventoryFull = "inventory_full"
        case entryRightsRemaining = "entry_rights_remaining"
        case spinRightsRemaining = "spin_rights_remaining"
        case totalProfit = "total_profit"
        case dailyProfit = "daily_profit"
        case weeklyProfit = "weekly_profit"
        case monthlyRevenue = "monthly_revenue"
        case taxDebt = "tax_debt"
        case lastTaxChargedDay = "last_tax_charged_day"
        case currentDay = "current_day"
        case passiveIncomeBalance = "passive_income_balance"
        case passiveIncomeUpdatedAt = "passive_income_updated_at"
        case totalTransactions = "total_transactions"
        case acceptedDeals = "accepted_deals"
        case rejectedDeals = "rejected_deals"
        case lifestyleScore = "lifestyle_score"
        case yesterdayCash = "yesterday_cash"
        case dailyRewardDay = "daily_reward_day"
        case dailyRewardClaimedAt = "daily_reward_claimed_at"
        case entryRightsRefreshedAt = "entry_rights_refreshed_at"
        case profitDayAnchorAt = "profit_day_anchor_at"
        case saveRevision = "save_revision"
    }
}

struct SavePlayerStatsPayload: Encodable {
    var shopName: String
    var activeShopKey: String?
    var playerCash: Double
    var inventoryUsd: Double
    var inventoryEur: Double
    var inventoryGram: Double
    var inventoryQuarter: Double
    var inventoryHalf: Double
    var inventoryFull: Double
    var entryRightsRemaining: Int
    var spinRightsRemaining: Int
    var totalProfit: Double
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
    var taxDebt: Double
    var lastTaxChargedDay: Int
    var currentDay: Int
    var passiveIncomeBalance: Double
    var passiveIncomeUpdatedAt: String
    var totalTransactions: Int
    var acceptedDeals: Int
    var rejectedDeals: Int
    var lifestyleScore: Int
    var yesterdayCash: Double
    var dailyRewardDay: Int
    var dailyRewardClaimedAt: String?
    var entryRightsRefreshedAt: String?
    var profitDayAnchorAt: String?
    var saveRevision: Int64

    enum CodingKeys: String, CodingKey {
        case shopName = "shop_name"
        case activeShopKey = "active_shop_key"
        case playerCash = "player_cash"
        case inventoryUsd = "inventory_usd"
        case inventoryEur = "inventory_eur"
        case inventoryGram = "inventory_gram"
        case inventoryQuarter = "inventory_quarter"
        case inventoryHalf = "inventory_half"
        case inventoryFull = "inventory_full"
        case entryRightsRemaining = "entry_rights_remaining"
        case spinRightsRemaining = "spin_rights_remaining"
        case totalProfit = "total_profit"
        case dailyProfit = "daily_profit"
        case weeklyProfit = "weekly_profit"
        case monthlyRevenue = "monthly_revenue"
        case taxDebt = "tax_debt"
        case lastTaxChargedDay = "last_tax_charged_day"
        case currentDay = "current_day"
        case passiveIncomeBalance = "passive_income_balance"
        case passiveIncomeUpdatedAt = "passive_income_updated_at"
        case totalTransactions = "total_transactions"
        case acceptedDeals = "accepted_deals"
        case rejectedDeals = "rejected_deals"
        case lifestyleScore = "lifestyle_score"
        case yesterdayCash = "yesterday_cash"
        case dailyRewardDay = "daily_reward_day"
        case dailyRewardClaimedAt = "daily_reward_claimed_at"
        case entryRightsRefreshedAt = "entry_rights_refreshed_at"
        case profitDayAnchorAt = "profit_day_anchor_at"
        case saveRevision = "save_revision"
    }

    init(from state: GameState) {
        let isoFormatter = ISO8601DateFormatter()
        shopName = state.shopName
        activeShopKey = state.activeShopKey
        playerCash = state.playerCash
        inventoryUsd = state.inventory.usd
        inventoryEur = state.inventory.eur
        inventoryGram = state.inventory.gramGold
        inventoryQuarter = state.inventory.quarterGold
        inventoryHalf = state.inventory.halfGold
        inventoryFull = state.inventory.fullGold
        entryRightsRemaining = state.entryRightsRemaining
        spinRightsRemaining = state.spinRightsRemaining
        totalProfit = state.totalProfit
        dailyProfit = state.dailyProfit
        weeklyProfit = state.weeklyProfit
        monthlyRevenue = state.monthlyRevenue
        taxDebt = state.taxDebt
        lastTaxChargedDay = state.lastTaxChargedDay
        currentDay = state.currentDay
        passiveIncomeBalance = state.passiveIncomeBalance
        passiveIncomeUpdatedAt = isoFormatter.string(from: state.passiveIncomeUpdatedAt)
        totalTransactions = state.totalTransactions
        acceptedDeals = state.acceptedDeals
        rejectedDeals = state.rejectedDeals
        lifestyleScore = state.lifestyleItems
            .filter(\.isOwned)
            .reduce(0) { $0 + $1.lifestylePoints }
        yesterdayCash = state.yesterdayCash
        dailyRewardDay = state.dailyRewardDay
        dailyRewardClaimedAt = state.dailyRewardClaimedAt.map { isoFormatter.string(from: $0) }
        entryRightsRefreshedAt = state.entryRightsRefreshedAt.map { isoFormatter.string(from: $0) }
        profitDayAnchorAt = state.profitDayAnchorAt.map { isoFormatter.string(from: $0) }
        saveRevision = state.saveRevision
    }
}

struct OwnedShopRow: Codable {
    var userId: UUID
    var shopKey: String?
    var shopName: String
    var employeeCount: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case shopKey = "shop_key"
        case shopName = "shop_name"
        case employeeCount = "employee_count"
    }
}

struct SaveOwnedShopPayload: Encodable {
    var shopKey: String
    var shopName: String
    var employeeCount: Int

    enum CodingKeys: String, CodingKey {
        case shopKey = "shop_key"
        case shopName = "shop_name"
        case employeeCount = "employee_count"
    }
}

struct LifestyleItemRow: Codable {
    var userId: UUID
    var itemName: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case itemName = "item_name"
    }
}

struct SaveLifestyleItemPayload: Encodable {
    var itemName: String

    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
    }
}

private struct SaveGameStateRequest: Encodable {
    let clientVersion: String
    let stats: SavePlayerStatsPayload
    let ownedShops: [SaveOwnedShopPayload]
    let lifestyleItems: [SaveLifestyleItemPayload]

    enum CodingKeys: String, CodingKey {
        case clientVersion = "client_version"
        case stats
        case ownedShops = "owned_shops"
        case lifestyleItems = "lifestyle_items"
    }
}

private struct SaveGameStateResponse: Decodable {
    let success: Bool
    let error: String?
}

struct GoldRatesRow: Codable {
    var gramBuy: Double
    var gramSell: Double
    var gramChangeDir: Int
    var quarterBuy: Double
    var quarterSell: Double
    var quarterChangeDir: Int
    var halfBuy: Double
    var halfSell: Double
    var halfChangeDir: Int
    var fullBuy: Double
    var fullSell: Double
    var fullChangeDir: Int
    var usdBuy: Double
    var usdSell: Double
    var usdChangeDir: Int
    var eurBuy: Double
    var eurSell: Double
    var eurChangeDir: Int
    var sourceName: String
    var fetchedAt: String

    enum CodingKeys: String, CodingKey {
        case gramBuy = "gram_buy"
        case gramSell = "gram_sell"
        case gramChangeDir = "gram_change_dir"
        case quarterBuy = "quarter_buy"
        case quarterSell = "quarter_sell"
        case quarterChangeDir = "quarter_change_dir"
        case halfBuy = "half_buy"
        case halfSell = "half_sell"
        case halfChangeDir = "half_change_dir"
        case fullBuy = "full_buy"
        case fullSell = "full_sell"
        case fullChangeDir = "full_change_dir"
        case usdBuy = "usd_buy"
        case usdSell = "usd_sell"
        case usdChangeDir = "usd_change_dir"
        case eurBuy = "eur_buy"
        case eurSell = "eur_sell"
        case eurChangeDir = "eur_change_dir"
        case sourceName = "source_name"
        case fetchedAt = "fetched_at"
    }
}

struct LeaderboardRow: Codable {
    var userId: UUID
    var shopName: String
    var playerCash: Double
    var inventoryGram: Double
    var inventoryQuarter: Double
    var inventoryHalf: Double
    var inventoryFull: Double
    var inventoryUsd: Double
    var inventoryEur: Double
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
    var totalProfit: Double
    var lifestyleScore: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case shopName = "shop_name"
        case playerCash = "player_cash"
        case inventoryGram = "inventory_gram"
        case inventoryQuarter = "inventory_quarter"
        case inventoryHalf = "inventory_half"
        case inventoryFull = "inventory_full"
        case inventoryUsd = "inventory_usd"
        case inventoryEur = "inventory_eur"
        case dailyProfit = "daily_profit"
        case weeklyProfit = "weekly_profit"
        case monthlyRevenue = "monthly_revenue"
        case totalProfit = "total_profit"
        case lifestyleScore = "lifestyle_score"
    }
}

struct DailyLeaderboardSnapshotRow: Codable {
    var snapshotDate: String
    var userId: UUID
    var shopName: String
    var totalNetWorth: Double
    var totalCash: Double
    var lifestyleScore: Int
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case snapshotDate = "snapshot_date"
        case userId = "user_id"
        case shopName = "shop_name"
        case totalNetWorth = "total_net_worth"
        case totalCash = "total_cash"
        case lifestyleScore = "lifestyle_score"
        case updatedAt = "updated_at"
    }
}

struct DailyLeaderboardSnapshot {
    let updatedAt: Date
    let entries: [LeaderboardEntry]
}

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
    var endsAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case icon
        case accentColor = "accent_color"
        case trafficModifier = "traffic_modifier"
        case generosityModifier = "generosity_modifier"
        case vipModifier = "vip_modifier"
        case isActive = "is_active"
        case endsAt = "ends_at"
    }
}

class SupabaseSaveService {
    private struct PendingSave {
        let accessToken: String
        let request: SaveGameStateRequest
    }

    private enum CloudLoadError: LocalizedError {
        case statsFetchFailed
        case shopsFetchFailed
        case lifestyleFetchFailed

        var errorDescription: String? {
            switch self {
            case .statsFetchFailed:
                return "Bulut oyuncu verisi alınamadı."
            case .shopsFetchFailed:
                return "Bulut dükkan verisi alınamadı."
            case .lifestyleFetchFailed:
                return "Bulut yaşam tarzı verisi alınamadı."
            }
        }
    }

    private struct SaveFailure: Error {
        let message: String
    }

    @MainActor private static var pendingSave: PendingSave?
    @MainActor private static var isProcessingSaveQueue = false

    private static func parseISODate(_ raw: String?) -> Date? {
        guard let raw else { return nil }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: raw) {
            return date
        }

        return ISO8601DateFormatter().date(from: raw)
    }

    private static func parseEventDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: raw) {
            return date
        }

        return ISO8601DateFormatter().date(from: raw)
    }

    @MainActor
    static func enqueueSave(_ state: GameState) {
        guard let accessToken = AuthService.shared.session?.accessToken else { return }
        state.cloudSyncStatus = .syncing
        state.cloudSyncErrorMessage = nil

        let request = SaveGameStateRequest(
            clientVersion: AppVersion.current.short,
            stats: SavePlayerStatsPayload(from: state),
            ownedShops: state.ownedShops.map {
                SaveOwnedShopPayload(shopKey: $0.key, shopName: $0.name, employeeCount: $0.employeeCount)
            },
            lifestyleItems: state.lifestyleItems
                .filter(\.isOwned)
                .map { SaveLifestyleItemPayload(itemName: $0.name) }
        )

        pendingSave = PendingSave(accessToken: accessToken, request: request)
        guard !isProcessingSaveQueue else { return }

        isProcessingSaveQueue = true
        Task {
            await processSaveQueue(for: state)
        }
    }

    private static func processSaveQueue(for state: GameState) async {
        while true {
            let nextSave: PendingSave? = await MainActor.run {
                guard let pendingSave else {
                    isProcessingSaveQueue = false
                    return nil
                }
                SupabaseSaveService.pendingSave = nil
                return pendingSave
            }

            guard let nextSave else { return }
            let result = await performSave(nextSave)

            await MainActor.run {
                switch result {
                case .success:
                    state.cloudSyncStatus = .synced
                    state.cloudSyncUpdatedAt = Date()
                    state.cloudSyncErrorMessage = nil
                case .failure(let failure):
                    state.cloudSyncStatus = .failed
                    state.cloudSyncErrorMessage = failure.message
                }
            }
        }
    }

    private static func performSave(_ pendingSave: PendingSave) async -> Result<Void, SaveFailure> {
        do {
            supabase.functions.setAuth(token: pendingSave.accessToken)
            let response: SaveGameStateResponse = try await supabase.functions.invoke(
                "save-game-state",
                options: FunctionInvokeOptions(method: .post, body: pendingSave.request)
            )

            if !response.success {
                let message = response.error ?? "Bilinmeyen hata"
                print("[SupabaseSave] save-game-state hata:", message)
                return .failure(SaveFailure(message: message))
            }
            return .success(())
        } catch {
            print("[SupabaseSave] save-game-state invoke hata:", error.localizedDescription)
            return .failure(SaveFailure(message: error.localizedDescription))
        }
    }

    @MainActor
    static func load(into state: GameState) async {
        guard let userId = AuthService.shared.userId else { return }

        async let statsResult = fetchStats(userId: userId)
        async let shopsResult = fetchShops(userId: userId)
        async let lifestyleResult = fetchLifestyle(userId: userId)

        let (statsFetch, shopsFetch, lifestyleFetch) = await (statsResult, shopsResult, lifestyleResult)

        switch statsFetch {
        case .failure:
            state.cloudSyncStatus = .failed
            state.cloudSyncErrorMessage = CloudLoadError.statsFetchFailed.errorDescription
            return
        case .success(.none):
            state.cloudSyncStatus = .idle
            state.cloudSyncErrorMessage = nil
            return
        case .success(.some(let stats)):
            if stats.saveRevision < state.saveRevision {
                enqueueSave(state)
                return
            }
            guard case .success(let shops) = shopsFetch else {
                state.cloudSyncStatus = .failed
                state.cloudSyncErrorMessage = CloudLoadError.shopsFetchFailed.errorDescription
                return
            }
            guard case .success(let lifestyle) = lifestyleFetch else {
                state.cloudSyncStatus = .failed
                state.cloudSyncErrorMessage = CloudLoadError.lifestyleFetchFailed.errorDescription
                return
            }

            applyStats(stats, to: state)
            applyShops(shops, to: state)
            restoreActiveShop(stats.activeShopKey, in: state)
            applyLifestyle(lifestyle, to: state)
            GameSaveService.save(state)
            state.cloudSyncStatus = .synced
            state.cloudSyncUpdatedAt = Date()
            state.cloudSyncErrorMessage = nil
        }
    }

    private static func fetchStats(userId: UUID) async -> Result<PlayerStatsRow?, Error> {
        do {
            let rows: [PlayerStatsRow] = try await supabase
                .from("player_stats")
                .select("user_id, shop_name, active_shop_key, player_cash, inventory_usd, inventory_eur, inventory_gram, inventory_quarter, inventory_half, inventory_full, entry_rights_remaining, spin_rights_remaining, total_profit, daily_profit, weekly_profit, monthly_revenue, tax_debt, last_tax_charged_day, current_day, passive_income_balance, passive_income_updated_at, total_transactions, accepted_deals, rejected_deals, lifestyle_score, yesterday_cash, daily_reward_day, daily_reward_claimed_at, entry_rights_refreshed_at, profit_day_anchor_at, save_revision")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            return .success(rows.first)
        } catch {
            return .failure(error)
        }
    }

    private static func fetchShops(userId: UUID) async -> Result<[OwnedShopRow], Error> {
        do {
            let rows: [OwnedShopRow] = try await supabase
                .from("owned_shops")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return .success(rows)
        } catch {
            return .failure(error)
        }
    }

    private static func fetchLifestyle(userId: UUID) async -> Result<[LifestyleItemRow], Error> {
        do {
            let rows: [LifestyleItemRow] = try await supabase
                .from("lifestyle_items")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return .success(rows)
        } catch {
            return .failure(error)
        }
    }

    private static func applyStats(_ row: PlayerStatsRow, to state: GameState) {
        state.shopName = row.shopName
        state.playerCash = row.playerCash
        state.inventory.usd = row.inventoryUsd
        state.inventory.eur = row.inventoryEur
        state.inventory.gramGold = row.inventoryGram
        state.inventory.quarterGold = row.inventoryQuarter
        state.inventory.halfGold = row.inventoryHalf
        state.inventory.fullGold = row.inventoryFull
        state.entryRightsRemaining = row.entryRightsRemaining
        state.spinRightsRemaining = row.spinRightsRemaining
        state.totalProfit = row.totalProfit
        state.dailyProfit = row.dailyProfit
        state.weeklyProfit = row.weeklyProfit
        state.monthlyRevenue = row.monthlyRevenue
        state.taxDebt = row.taxDebt
        state.lastTaxChargedDay = row.lastTaxChargedDay
        state.currentDay = row.currentDay
        state.passiveIncomeBalance = row.passiveIncomeBalance ?? 0
        state.passiveIncomeUpdatedAt = parseISODate(row.passiveIncomeUpdatedAt) ?? Date()
        state.totalTransactions = row.totalTransactions
        state.acceptedDeals = row.acceptedDeals
        state.rejectedDeals = row.rejectedDeals
        state.lifestyleScore = row.lifestyleScore
        state.yesterdayCash = row.yesterdayCash

        let supabaseClaimedAt = parseISODate(row.dailyRewardClaimedAt)
        if let supabaseDate = supabaseClaimedAt {
            if state.dailyRewardClaimedAt == nil || supabaseDate >= state.dailyRewardClaimedAt! {
                state.dailyRewardDay = row.dailyRewardDay
                state.dailyRewardClaimedAt = supabaseDate
            }
        } else if state.dailyRewardClaimedAt == nil {
            state.dailyRewardDay = row.dailyRewardDay
        }

        let supabaseEntryRefreshDate = parseISODate(row.entryRightsRefreshedAt)
        if let supabaseEntryRefreshDate {
            state.entryRightsRefreshedAt = supabaseEntryRefreshDate
        }
        let supabaseProfitDayAnchorAt = parseISODate(row.profitDayAnchorAt)
        if let supabaseProfitDayAnchorAt {
            state.profitDayAnchorAt = supabaseProfitDayAnchorAt
        }
        state.saveRevision = max(state.saveRevision, row.saveRevision)
        state.syncEntryRightsIfNeeded()
        state.syncProfitPeriodsIfNeeded(persistsChanges: true, syncsCloud: false)
    }

    private static func applyShops(_ rows: [OwnedShopRow], to state: GameState) {
        guard !rows.isEmpty else { return }

        let allShops = GameSeedData.allShops
        let normalizedRows = rows.compactMap { row -> (key: String, employeeCount: Int)? in
            let key = row.shopKey ?? GameSeedData.allShops.first(where: { $0.name == row.shopName })?.key
            guard let key else { return nil }
            return (key, row.employeeCount)
        }
        let ownedKeys = Set(normalizedRows.map(\.key))
        let employeeMap = Dictionary(uniqueKeysWithValues: normalizedRows.map { ($0.key, $0.employeeCount) })

        state.ownedShops = allShops
            .filter { ownedKeys.contains($0.key) }
            .map { shop in
                var restoredShop = shop
                restoredShop.isOwned = true
                restoredShop.employeeCount = employeeMap[shop.key] ?? shop.employeeCount
                return restoredShop
            }
        state.lockedShops = allShops.filter { !ownedKeys.contains($0.key) }
    }

    private static func restoreActiveShop(_ activeShopKey: String?, in state: GameState) {
        state.activeShop = state.ownedShops.first(where: { $0.key == activeShopKey }) ?? state.ownedShops.first
    }

    private static func applyLifestyle(_ rows: [LifestyleItemRow], to state: GameState) {
        let ownedNames = Set(rows.map(\.itemName))
        for index in state.lifestyleItems.indices {
            state.lifestyleItems[index].isOwned = ownedNames.contains(state.lifestyleItems[index].name)
        }
        state.recalculateLifestyleScore()
    }

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
                guard let index = state.rates.firstIndex(where: { $0.type == type }) else { return }
                state.rates[index].buyPrice = buy
                state.rates[index].sellPrice = sell
                state.rates[index].changeDir = changeDir
                state.rates[index].sourceName = row.sourceName
                state.rates[index].sourceDate = row.fetchedAt
            }

            await MainActor.run {
                apply("gramGold", buy: row.gramBuy, sell: row.gramSell, changeDir: row.gramChangeDir)
                apply("quarterGold", buy: row.quarterBuy, sell: row.quarterSell, changeDir: row.quarterChangeDir)
                apply("halfGold", buy: row.halfBuy, sell: row.halfSell, changeDir: row.halfChangeDir)
                apply("fullGold", buy: row.fullBuy, sell: row.fullSell, changeDir: row.fullChangeDir)
                apply("USD", buy: row.usdBuy, sell: row.usdSell, changeDir: row.usdChangeDir)
                apply("EUR", buy: row.eurBuy, sell: row.eurSell, changeDir: row.eurChangeDir)
            }
        } catch {
            print("[SupabaseSave] gold_rates hata:", error.localizedDescription)
        }
    }

    static func loadEvents(into state: GameState) async {
        do {
            let rows: [EventRow] = try await supabase
                .from("game_events")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value

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
                    endsAt: parseEventDate(row.endsAt)
                )
            }
            await MainActor.run { state.activeEvents = events }
        } catch {
            print("[SupabaseSave] game_events hata:", error.localizedDescription)
        }
    }

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
                    + row.inventoryGram * price("gramGold")
                    + row.inventoryQuarter * price("quarterGold")
                    + row.inventoryHalf * price("halfGold")
                    + row.inventoryFull * price("fullGold")
                    + row.inventoryUsd * price("USD")
                    + row.inventoryEur * price("EUR")

                return LeaderboardEntry(
                    id: row.userId,
                    playerName: row.shopName,
                    dailyProfit: row.dailyProfit,
                    weeklyProfit: row.weeklyProfit,
                    monthlyRevenue: row.monthlyRevenue,
                    netWorth: netWorth,
                    cashBalance: row.playerCash,
                    lifestylePoints: row.lifestyleScore,
                    isPlayer: false
                )
            }
        } catch {
            print("[SupabaseSave] leaderboard hata:", error.localizedDescription)
            return []
        }
    }

    static func fetchDailyLeaderboardSnapshot() async -> DailyLeaderboardSnapshot? {
        do {
            struct LatestSnapshotDateRow: Decodable {
                let snapshotDate: String

                enum CodingKeys: String, CodingKey {
                    case snapshotDate = "snapshot_date"
                }
            }

            let latestDateRow: LatestSnapshotDateRow = try await supabase
                .from("daily_leaderboard_snapshots")
                .select("snapshot_date")
                .order("snapshot_date", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value

            let rows: [DailyLeaderboardSnapshotRow] = try await supabase
                .from("daily_leaderboard_snapshots")
                .select("snapshot_date, user_id, shop_name, total_net_worth, total_cash, lifestyle_score, updated_at")
                .eq("snapshot_date", value: latestDateRow.snapshotDate)
                .execute()
                .value

            guard let firstRow = rows.first,
                  let updatedAt = parseISODate(firstRow.updatedAt) else {
                return nil
            }

            let entries = rows.map { row in
                LeaderboardEntry(
                    id: row.userId,
                    playerName: row.shopName,
                    dailyProfit: 0,
                    weeklyProfit: 0,
                    monthlyRevenue: 0,
                    netWorth: row.totalNetWorth,
                    cashBalance: row.totalCash,
                    lifestylePoints: row.lifestyleScore,
                    isPlayer: false
                )
            }

            return DailyLeaderboardSnapshot(updatedAt: updatedAt, entries: entries)
        } catch {
            print("[SupabaseSave] daily leaderboard snapshot hata:", error.localizedDescription)
            return nil
        }
    }
}
