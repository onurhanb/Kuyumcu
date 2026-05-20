import Foundation

/// Lightweight UserDefaults-based persistence for numeric game state.
/// Shop / inventory / upgrade objects are re-created from seed data on fresh launch;
/// only the numeric progression fields survive across restarts.
class GameSaveService {

    private static let key = "goldDealerLifeSave_v1"

    static func save(_ state: GameState) {
        let dict: [String: Any] = [
            "playerCash":                  state.playerCash,
            "inventoryTRY":                state.inventory.tryCash,
            "inventoryUSD":                state.inventory.usd,
            "inventoryEUR":                state.inventory.eur,
            "inventoryGram":               state.inventory.gramGold,
            "inventoryQuarter":            state.inventory.quarterGold,
            "inventoryHalf":               state.inventory.halfGold,
            "inventoryFull":               state.inventory.fullGold,
            "customerSatisfaction":        state.customerSatisfaction,
            "totalProfit":                 state.totalProfit,
            "dailyProfit":                 state.dailyProfit,
            "weeklyProfit":                state.weeklyProfit,
            "monthlyRevenue":              state.monthlyRevenue,
            "currentDay":                  state.currentDay,
            "passiveIncomeBalance":        state.passiveIncomeBalance,
            "passiveIncomeUpdatedAt":      state.passiveIncomeUpdatedAt.timeIntervalSince1970,
            "totalTransactions":           state.totalTransactions,
            "acceptedDeals":               state.acceptedDeals,
            "rejectedDeals":               state.rejectedDeals,
            "yesterdayCash":               state.yesterdayCash,
            "trustScore":                  state.trustScore,
            "shopName":                    state.shopName,
            // Owned shop names (simplified – match by name on load)
            "ownedShopNames":              state.ownedShops.map { $0.name },
            "ownedShopEmployeeCounts":      Dictionary(uniqueKeysWithValues: state.ownedShops.map { ($0.name, $0.employeeCount) }),
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
        ]
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func load(into state: GameState) {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) else { return }

        state.playerCash                  = dict["playerCash"]                  as? Double ?? state.playerCash
        state.inventory.tryCash           = dict["inventoryTRY"]                as? Double ?? state.inventory.tryCash
        state.inventory.usd               = dict["inventoryUSD"]                as? Double ?? state.inventory.usd
        state.inventory.eur               = dict["inventoryEUR"]                as? Double ?? state.inventory.eur
        state.inventory.gramGold          = dict["inventoryGram"]               as? Double ?? state.inventory.gramGold
        state.inventory.quarterGold       = dict["inventoryQuarter"]            as? Double ?? state.inventory.quarterGold
        state.inventory.halfGold          = dict["inventoryHalf"]               as? Double ?? state.inventory.halfGold
        state.inventory.fullGold          = dict["inventoryFull"]               as? Double ?? state.inventory.fullGold
        state.customerSatisfaction        = dict["customerSatisfaction"]        as? Int    ?? state.customerSatisfaction
        state.totalProfit                 = dict["totalProfit"]                 as? Double ?? state.totalProfit
        state.dailyProfit                 = dict["dailyProfit"]                 as? Double ?? state.dailyProfit
        state.weeklyProfit                = dict["weeklyProfit"]                as? Double ?? state.weeklyProfit
        state.monthlyRevenue              = dict["monthlyRevenue"]              as? Double ?? state.monthlyRevenue
        state.currentDay                  = dict["currentDay"]                  as? Int    ?? state.currentDay
        state.passiveIncomeBalance        = dict["passiveIncomeBalance"]        as? Double ?? state.passiveIncomeBalance
        if let savedTs = dict["passiveIncomeUpdatedAt"] as? Double, savedTs > 0 {
            state.passiveIncomeUpdatedAt = Date(timeIntervalSince1970: savedTs)
        }
        state.totalTransactions           = dict["totalTransactions"]           as? Int    ?? state.totalTransactions
        state.acceptedDeals               = dict["acceptedDeals"]               as? Int    ?? state.acceptedDeals
        state.rejectedDeals               = dict["rejectedDeals"]               as? Int    ?? state.rejectedDeals
        state.yesterdayCash               = dict["yesterdayCash"]               as? Double ?? state.yesterdayCash
        state.trustScore                  = dict["trustScore"]                  as? Double ?? state.trustScore
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
        if let ownedNames = dict["ownedShopNames"] as? [String] {
            let allShops = GameSeedData.allShops
            let employeeCounts = dict["ownedShopEmployeeCounts"] as? [String: Int] ?? [:]
            state.ownedShops  = allShops.filter { ownedNames.contains($0.name) }.map {
                var s = $0
                s.isOwned = true
                s.employeeCount = employeeCounts[s.name] ?? s.employeeCount
                return s
            }
            state.lockedShops = allShops.filter { !ownedNames.contains($0.name) }
            state.activeShop  = state.ownedShops.first
        }

        // Restore owned lifestyle items
        if let ownedNames = dict["lifestyleOwnedNames"] as? [String] {
            let nameSet = Set(ownedNames)
            for i in state.lifestyleItems.indices {
                state.lifestyleItems[i].isOwned = nameSet.contains(state.lifestyleItems[i].name)
            }
        }

        // Daily reward yerel yedeği (sadece Supabase değerler boşsa kullanılır)
        if state.dailyRewardDay == 0,
           let savedDay = dict["dailyRewardDay"] as? Int, savedDay > 0 {
            state.dailyRewardDay = savedDay
        }
        if state.dailyRewardClaimedAt == nil,
           let savedTs = dict["dailyRewardClaimedAt"] as? Double, savedTs > 0 {
            state.dailyRewardClaimedAt = Date(timeIntervalSince1970: savedTs)
        }
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Oyun günü 08:00 İstanbul saatinde başlar. İki tarihin aynı oyun gününe ait olup olmadığını kontrol eder.
    private static func isSameGameDay(_ d1: Date, _ d2: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        func gameDayStart(for date: Date) -> Date {
            var comps = cal.dateComponents([.year, .month, .day], from: date)
            comps.hour = 8; comps.minute = 0; comps.second = 0
            let dayStart = cal.date(from: comps)!
            return date < dayStart ? cal.date(byAdding: .day, value: -1, to: dayStart)! : dayStart
        }

        return gameDayStart(for: d1) == gameDayStart(for: d2)
    }
}
