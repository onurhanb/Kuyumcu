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
    var totalProfit: Double
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
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
        case totalProfit = "total_profit"
        case dailyProfit = "daily_profit"
        case weeklyProfit = "weekly_profit"
        case monthlyRevenue = "monthly_revenue"
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
    var totalProfit: Double
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
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
        case totalProfit = "total_profit"
        case dailyProfit = "daily_profit"
        case weeklyProfit = "weekly_profit"
        case monthlyRevenue = "monthly_revenue"
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
        totalProfit = state.totalProfit
        dailyProfit = state.dailyProfit
        weeklyProfit = state.weeklyProfit
        monthlyRevenue = state.monthlyRevenue
        currentDay = state.currentDay
        passiveIncomeBalance = state.passiveIncomeBalance
        passiveIncomeUpdatedAt = isoFormatter.string(from: state.passiveIncomeUpdatedAt)
        totalTransactions = state.totalTransactions
        acceptedDeals = state.acceptedDeals
        rejectedDeals = state.rejectedDeals
        lifestyleScore = state.lifestyleScore
        yesterdayCash = state.yesterdayCash
        dailyRewardDay = state.dailyRewardDay
        dailyRewardClaimedAt = state.dailyRewardClaimedAt.map { isoFormatter.string(from: $0) }
        entryRightsRefreshedAt = state.entryRightsRefreshedAt.map { isoFormatter.string(from: $0) }
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

    static func save(_ state: GameState) async {
        guard let accessToken = AuthService.shared.session?.accessToken else { return }
        await MainActor.run {
            state.cloudSyncStatus = .syncing
            state.cloudSyncErrorMessage = nil
        }

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

        do {
            supabase.functions.setAuth(token: accessToken)
            let response: SaveGameStateResponse = try await supabase.functions.invoke(
                "save-game-state",
                options: FunctionInvokeOptions(method: .post, body: request)
            )

            if !response.success {
                let message = response.error ?? "Bilinmeyen hata"
                print("[SupabaseSave] save-game-state hata:", message)
                await MainActor.run {
                    state.cloudSyncStatus = .failed
                    state.cloudSyncErrorMessage = message
                }
                return
            }
            await MainActor.run {
                state.cloudSyncStatus = .synced
                state.cloudSyncUpdatedAt = Date()
            }
        } catch {
            print("[SupabaseSave] save-game-state invoke hata:", error.localizedDescription)
            await MainActor.run {
                state.cloudSyncStatus = .failed
                state.cloudSyncErrorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    static func load(into state: GameState) async {
        guard let userId = AuthService.shared.userId else { return }

        async let statsResult = fetchStats(userId: userId)
        async let shopsResult = fetchShops(userId: userId)
        async let lifestyleResult = fetchLifestyle(userId: userId)

        let (stats, shops, lifestyle) = await (statsResult, shopsResult, lifestyleResult)

        var activeShopKey: String?
        if let stats {
            applyStats(stats, to: state)
            activeShopKey = stats.activeShopKey
        }
        if let shops {
            applyShops(shops, to: state)
        }
        restoreActiveShop(activeShopKey, in: state)
        if let lifestyle {
            applyLifestyle(lifestyle, to: state)
        }
    }

    private static func fetchStats(userId: UUID) async -> PlayerStatsRow? {
        do {
            let row: PlayerStatsRow = try await supabase
                .from("player_stats")
                .select("user_id, shop_name, active_shop_key, player_cash, inventory_usd, inventory_eur, inventory_gram, inventory_quarter, inventory_half, inventory_full, entry_rights_remaining, total_profit, daily_profit, weekly_profit, monthly_revenue, current_day, passive_income_balance, passive_income_updated_at, total_transactions, accepted_deals, rejected_deals, lifestyle_score, yesterday_cash, daily_reward_day, daily_reward_claimed_at, entry_rights_refreshed_at")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return row
        } catch {
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
        state.totalProfit = row.totalProfit
        state.dailyProfit = row.dailyProfit
        state.weeklyProfit = row.weeklyProfit
        state.monthlyRevenue = row.monthlyRevenue
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
        state.syncEntryRightsIfNeeded()
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
