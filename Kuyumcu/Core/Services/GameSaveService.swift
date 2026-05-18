import Foundation

/// Lightweight UserDefaults-based persistence for numeric game state.
/// Shop / inventory / upgrade objects are re-created from MockData on fresh launch;
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
            "passiveIncomeCollectedToday": state.passiveIncomeCollectedToday,
            "totalTransactions":           state.totalTransactions,
            "acceptedDeals":               state.acceptedDeals,
            "rejectedDeals":               state.rejectedDeals,
            "yesterdayCash":               state.yesterdayCash,
            "previousRatePrices":          state.previousRatePrices,
            "trustScore":                  state.trustScore,
            "shopName":                    state.shopName,
            "isGuest":                     state.isGuest,
            // Owned shop names (simplified – match by name on load)
            "ownedShopNames":              state.ownedShops.map { $0.name },
            // Rates cache
            "ratesBuyPrices":              Dictionary(uniqueKeysWithValues: state.rates.map { ($0.type, $0.buyPrice) }),
            "ratesSellPrices":             Dictionary(uniqueKeysWithValues: state.rates.map { ($0.type, $0.sellPrice) }),
            "ratesSourceName":             state.rates.first?.sourceName ?? "",
            "ratesSourceDate":             state.rates.first?.sourceDate ?? "",
            // Owned lifestyle items (name used as stable key)
            "lifestyleOwnedNames":         state.lifestyleItems.filter { $0.isOwned }.map { $0.name },
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
        state.passiveIncomeCollectedToday = dict["passiveIncomeCollectedToday"] as? Bool   ?? false
        state.totalTransactions           = dict["totalTransactions"]           as? Int    ?? state.totalTransactions
        state.acceptedDeals               = dict["acceptedDeals"]               as? Int    ?? state.acceptedDeals
        state.rejectedDeals               = dict["rejectedDeals"]               as? Int    ?? state.rejectedDeals
        state.yesterdayCash               = dict["yesterdayCash"]               as? Double        ?? state.yesterdayCash
        state.previousRatePrices          = dict["previousRatePrices"]          as? [String: Double] ?? [:]
        state.trustScore                  = dict["trustScore"]                  as? Double ?? state.trustScore
        state.shopName                    = dict["shopName"]                    as? String ?? state.shopName
        state.isGuest                     = dict["isGuest"]                     as? Bool   ?? state.isGuest

        // Restore cached rates (overwrites mock values if available)
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
            let allShops = MockGameData.allShops
            state.ownedShops  = allShops.filter { ownedNames.contains($0.name) }.map { var s = $0; s.isOwned = true; return s }
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
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
