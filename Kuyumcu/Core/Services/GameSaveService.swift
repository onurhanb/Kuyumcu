import Foundation

/// Lightweight UserDefaults-based persistence for numeric game state.
/// Shop / inventory / upgrade objects are re-created from seed data on fresh launch;
/// only the numeric progression fields survive across restarts.
class GameSaveService {

    private static let key = "goldDealerLifeSave_v1"

    @MainActor
    static func save(_ state: GameState) {
        let dict: [String: Any] = [
            "playerCash":                  state.playerCash,
            "inventoryUSD":                state.inventory.usd,
            "inventoryEUR":                state.inventory.eur,
            "inventoryGram":               state.inventory.gramGold,
            "inventoryQuarter":            state.inventory.quarterGold,
            "inventoryHalf":               state.inventory.halfGold,
            "inventoryFull":               state.inventory.fullGold,
            "entryRightsRemaining":        state.entryRightsRemaining,
            "spinRightsRemaining":         state.spinRightsRemaining,
            "totalProfit":                 state.totalProfit,
            "dailyProfit":                 state.dailyProfit,
            "weeklyProfit":                state.weeklyProfit,
            "monthlyRevenue":              state.monthlyRevenue,
            "taxDebt":                     state.taxDebt,
            "lastTaxChargedDay":           state.lastTaxChargedDay,
            "currentDay":                  state.currentDay,
            "passiveIncomeBalance":        state.passiveIncomeBalance,
            "passiveIncomeUpdatedAt":      state.passiveIncomeUpdatedAt.timeIntervalSince1970,
            "totalTransactions":           state.totalTransactions,
            "acceptedDeals":               state.acceptedDeals,
            "rejectedDeals":               state.rejectedDeals,
            "yesterdayCash":               state.yesterdayCash,
            "shopName":                    state.shopName,
            "ownedShopKeys":               state.ownedShops.map { $0.key },
            "ownedShopNames":              state.ownedShops.map { $0.name },
            "ownedShopEmployeeCounts":     Dictionary(uniqueKeysWithValues: state.ownedShops.map { ($0.key, $0.employeeCount) }),
            "activeShopKey":               state.activeShopKey ?? "",
            // Rates cache
            "ratesBuyPrices":              Dictionary(uniqueKeysWithValues: state.rates.map { ($0.type, $0.buyPrice) }),
            "ratesSellPrices":             Dictionary(uniqueKeysWithValues: state.rates.map { ($0.type, $0.sellPrice) }),
            "ratesSourceName":             state.rates.first?.sourceName ?? "",
            "ratesSourceDate":             state.rates.first?.sourceDate ?? "",
            // Owned lifestyle items (name used as stable key)
            "lifestyleOwnedNames":         state.lifestyleItems.filter { $0.isOwned }.map { $0.name },
            // Daily reward (yerel yedek — Supabase yetersiz kalırsa devreye girer)
            "dailyRewardDay":               state.dailyRewardDay,
            "dailyRewardClaimedAt":         state.dailyRewardClaimedAt?.timeIntervalSince1970 ?? -1,
            "entryRightsRefreshedAt":       state.entryRightsRefreshedAt?.timeIntervalSince1970 ?? -1,
            "profitDayAnchorAt":            state.profitDayAnchorAt?.timeIntervalSince1970 ?? -1,
            "saveRevision":                 state.saveRevision,
        ]
        UserDefaults.standard.set(dict, forKey: key)
    }

    @MainActor
    static func load(into state: GameState) {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) else { return }

        let legacyInventoryCash = dict["inventoryTRY"] as? Double
        state.playerCash                  = dict["playerCash"]                  as? Double ?? legacyInventoryCash ?? state.playerCash
        state.inventory.usd               = dict["inventoryUSD"]                as? Double ?? state.inventory.usd
        state.inventory.eur               = dict["inventoryEUR"]                as? Double ?? state.inventory.eur
        state.inventory.gramGold          = dict["inventoryGram"]               as? Double ?? state.inventory.gramGold
        state.inventory.quarterGold       = dict["inventoryQuarter"]            as? Double ?? state.inventory.quarterGold
        state.inventory.halfGold          = dict["inventoryHalf"]               as? Double ?? state.inventory.halfGold
        state.inventory.fullGold          = dict["inventoryFull"]               as? Double ?? state.inventory.fullGold
        state.entryRightsRemaining        = dict["entryRightsRemaining"]        as? Int    ?? state.entryRightsRemaining
        state.spinRightsRemaining         = dict["spinRightsRemaining"]         as? Int    ?? state.spinRightsRemaining
        state.totalProfit                 = dict["totalProfit"]                 as? Double ?? state.totalProfit
        state.dailyProfit                 = dict["dailyProfit"]                 as? Double ?? state.dailyProfit
        state.weeklyProfit                = dict["weeklyProfit"]                as? Double ?? state.weeklyProfit
        state.monthlyRevenue              = dict["monthlyRevenue"]              as? Double ?? state.monthlyRevenue
        state.taxDebt                     = dict["taxDebt"]                     as? Double ?? state.taxDebt
        state.lastTaxChargedDay           = dict["lastTaxChargedDay"]           as? Int    ?? state.lastTaxChargedDay
        state.currentDay                  = dict["currentDay"]                  as? Int    ?? state.currentDay
        state.passiveIncomeBalance        = dict["passiveIncomeBalance"]        as? Double ?? state.passiveIncomeBalance
        if let savedTs = dict["passiveIncomeUpdatedAt"] as? Double, savedTs > 0 {
            state.passiveIncomeUpdatedAt = Date(timeIntervalSince1970: savedTs)
        }
        state.totalTransactions           = dict["totalTransactions"]           as? Int    ?? state.totalTransactions
        state.acceptedDeals               = dict["acceptedDeals"]               as? Int    ?? state.acceptedDeals
        state.rejectedDeals               = dict["rejectedDeals"]               as? Int    ?? state.rejectedDeals
        state.yesterdayCash               = dict["yesterdayCash"]               as? Double ?? state.yesterdayCash
        state.shopName                    = dict["shopName"]                    as? String ?? state.shopName

        // Restore cached rates (overwrites kayıtlı values if available)
        if let buyPrices  = dict["ratesBuyPrices"]  as? [String: Double],
           let sellPrices = dict["ratesSellPrices"] as? [String: Double] {
            let srcName = dict["ratesSourceName"] as? String ?? ""
            let srcDate = dict["ratesSourceDate"] as? String ?? ""
            for i in state.rates.indices {
                let t = state.rates[i].type
                if let buy = buyPrices[t], let sell = sellPrices[t] {
                    state.rates[i].buyPrice   = buy
                    state.rates[i].sellPrice  = sell
                    state.rates[i].sourceName = srcName
                    state.rates[i].sourceDate = srcDate
                }
            }
        }

        // Restore owned shops
        if let ownedKeys = dict["ownedShopKeys"] as? [String] {
            let allShops = GameSeedData.allShops
            let employeeCounts = dict["ownedShopEmployeeCounts"] as? [String: Int] ?? [:]
            state.ownedShops  = allShops.filter { ownedKeys.contains($0.key) }.map {
                var s = $0
                s.isOwned = true
                s.employeeCount = employeeCounts[s.key] ?? s.employeeCount
                return s
            }
            state.lockedShops = allShops.filter { !ownedKeys.contains($0.key) }
            let activeShopKey = dict["activeShopKey"] as? String
            state.activeShop = state.ownedShops.first(where: { $0.key == activeShopKey }) ?? state.ownedShops.first
        } else if let ownedNames = dict["ownedShopNames"] as? [String] {
            let allShops = GameSeedData.allShops
            state.ownedShops = allShops.filter { ownedNames.contains($0.name) }.map {
                var s = $0
                s.isOwned = true
                return s
            }
            state.lockedShops = allShops.filter { !ownedNames.contains($0.name) }
            state.activeShop = state.ownedShops.first
        }

        // Restore owned lifestyle items
        if let ownedNames = dict["lifestyleOwnedNames"] as? [String] {
            let nameSet = Set(ownedNames)
            for i in state.lifestyleItems.indices {
                state.lifestyleItems[i].isOwned = nameSet.contains(state.lifestyleItems[i].name)
            }
        }
        state.recalculateLifestyleScore()

        // Daily reward yerel yedeği (sadece Supabase değerler boşsa kullanılır)
        if state.dailyRewardDay == 0,
           let savedDay = dict["dailyRewardDay"] as? Int, savedDay > 0 {
            state.dailyRewardDay = savedDay
        }
        if state.dailyRewardClaimedAt == nil,
           let savedTs = dict["dailyRewardClaimedAt"] as? Double, savedTs > 0 {
            state.dailyRewardClaimedAt = Date(timeIntervalSince1970: savedTs)
        }
        if state.entryRightsRefreshedAt == nil,
           let savedTs = dict["entryRightsRefreshedAt"] as? Double, savedTs > 0 {
            state.entryRightsRefreshedAt = Date(timeIntervalSince1970: savedTs)
        }
        if state.profitDayAnchorAt == nil,
           let savedTs = dict["profitDayAnchorAt"] as? Double, savedTs > 0 {
            state.profitDayAnchorAt = Date(timeIntervalSince1970: savedTs)
        }
        state.saveRevision = dict["saveRevision"] as? Int64 ?? Int64(dict["saveRevision"] as? Int ?? 0)
        state.syncEntryRightsIfNeeded()
        state.syncProfitPeriodsIfNeeded(persistsChanges: true, syncsCloud: false)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

}
