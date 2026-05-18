import Foundation

// MARK: - Currency & Gold Types

enum CurrencyType: String, Codable, CaseIterable {
    case TRY, USD, EUR
}

enum GoldProductType: String, Codable, CaseIterable {
    case gram, quarter, half, full

    var displayName: String {
        switch self {
        case .gram:    return "Gram Altın"
        case .quarter: return "Çeyrek Altın"
        case .half:    return "Yarım Altın"
        case .full:    return "Tam Altın"
        }
    }
}

// MARK: - Lifestyle

enum LifestyleCategory: String, Codable, CaseIterable {
    case daily        = "Günlük"
    case vehicle      = "Taşıt"
    case realEstate   = "Gayrimenkul"
    case luxury       = "Lüks"
    case experience   = "Deneyim"

    var icon: String {
        switch self {
        case .daily:      return "bag.fill"
        case .vehicle:    return "car.fill"
        case .realEstate: return "house.fill"
        case .luxury:     return "crown.fill"
        case .experience: return "airplane"
        }
    }
}

struct LifestyleItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var category: LifestyleCategory
    var price: Double       // TL
    var lifestylePoints: Int
    var icon: String
    var isOwned: Bool = false
}

// MARK: - Rate

struct Rate: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: String        // "gramGold" | "quarterGold" | "halfGold" | "fullGold" | "USD" | "EUR"
    var buyPrice: Double    // Alış fiyatı (biz alırken)
    var sellPrice: Double   // Satış fiyatı (biz satarken)
    var sourceName: String
    var sourceDate: String
}

// MARK: - Inventory

struct Inventory: Codable {
    var tryCash: Double
    var usd: Double
    var eur: Double
    var gramGold: Double
    var quarterGold: Double
    var halfGold: Double
    var fullGold: Double
}

// MARK: - Shop

enum ShopLocationType: String, Codable, CaseIterable {
    case neighborhood
    case bazaar
    case districtBazaar
    case cityCenter
    case mall
    case grandBazaar

    var displayName: String {
        switch self {
        case .neighborhood:   return "Mahalle"
        case .bazaar:         return "Çarşı"
        case .districtBazaar: return "İlçe"
        case .cityCenter:     return "Şehir Merkezi"
        case .mall:           return "AVM"
        case .grandBazaar:    return "Kapalıçarşı"
        }
    }

    var icon: String {
        switch self {
        case .neighborhood:   return "house.fill"
        case .bazaar:         return "cart.fill"
        case .districtBazaar: return "building.2.fill"
        case .cityCenter:     return "building.fill"
        case .mall:           return "storefront.fill"
        case .grandBazaar:    return "crown.fill"
        }
    }

    var employeeHireCost: Double {
        switch self {
        case .neighborhood:   return 20_000
        case .bazaar:         return 30_000
        case .districtBazaar: return 40_000
        case .cityCenter:     return 50_000
        case .mall:           return 60_000
        case .grandBazaar:    return 70_000
        }
    }

    /// Günlük toplam müşteri limiti (250'şer artar)
    var dailyCustomerLimit: Int {
        switch self {
        case .neighborhood:   return 250
        case .bazaar:         return 500
        case .districtBazaar: return 750
        case .cityCenter:     return 1000
        case .mall:           return 1250
        case .grandBazaar:    return 1500
        }
    }

    /// Aynı anda bekleme sırasında durabilecek maksimum müşteri (5'er artar)
    var queueCapacity: Int {
        switch self {
        case .neighborhood:   return 5
        case .bazaar:         return 10
        case .districtBazaar: return 15
        case .cityCenter:     return 20
        case .mall:           return 25
        case .grandBazaar:    return 30
        }
    }
}

struct Shop: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var locationType: ShopLocationType
    var level: Int
    var purchasePrice: Double
    var dailyPassiveBaseIncome: Double
    var passiveMultiplier: Double
    var customerTrafficMultiplier: Double
    var vipChance: Double
    var employeeCapacity: Int
    var employeeCount: Int
    var isOwned: Bool

    static func == (lhs: Shop, rhs: Shop) -> Bool { lhs.id == rhs.id }
}

// MARK: - Customer

enum CustomerType: String, Codable, CaseIterable {
    case regular, frugal, generous, urgent, tourist, vip

    var displayName: String {
        switch self {
        case .regular:  return "Normal"
        case .frugal:   return "Tutumlu"
        case .generous: return "Cömert"
        case .urgent:   return "Acil"
        case .tourist:  return "Turist"
        case .vip:      return "VIP"
        }
    }

    var badgeColor: String {
        switch self {
        case .regular:  return "gray"
        case .frugal:   return "orange"
        case .generous: return "green"
        case .urgent:   return "red"
        case .tourist:  return "blue"
        case .vip:      return "gold"
        }
    }

    // Müşterinin piyasa üzeri fiyatı ne kadar tolere ettiği (alım yönünde)
    // frugal=0.60 → çok fiyat hassas; vip=1.40 → yüksek fiyatı kabul eder
    var marginTolerance: Double {
        switch self {
        case .regular:  return 1.00
        case .frugal:   return 0.60
        case .generous: return 1.50
        case .urgent:   return 1.30
        case .tourist:  return 1.35
        case .vip:      return 1.40
        }
    }
}

enum TransactionDirection: String, Codable {
    case customerBuysFromPlayer  // Player sells → we want higher offer
    case customerSellsToPlayer   // Player buys  → we want lower offer

    var displayName: String {
        switch self {
        case .customerBuysFromPlayer: return "Satış"
        case .customerSellsToPlayer:  return "Alım"
        }
    }
}

enum ProductCategory: String, Codable {
    case goldGram, goldQuarter, goldHalf, goldFull
    case currencyUSD, currencyEUR
    case jewelry

    var displayName: String {
        switch self {
        case .goldGram:     return "Gram Altın"
        case .goldQuarter:  return "Çeyrek Altın"
        case .goldHalf:     return "Yarım Altın"
        case .goldFull:     return "Tam Altın"
        case .currencyUSD:  return "Dolar (USD)"
        case .currencyEUR:  return "Euro (EUR)"
        case .jewelry:      return "Mücevher (gram)"
        }
    }
}

struct RequestItem: Codable, Identifiable {
    var id: UUID = UUID()
    var productCategory: ProductCategory
    var quantity: Double
    var label: String   // Görüntülenecek metin, örn. "5 Tam Altın"
}

struct CustomerRequest: Identifiable, Codable {
    var id: UUID
    var direction: TransactionDirection
    var items: [RequestItem]
}

struct Customer: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var age: Int
    var trait: String
    var generosity: Double        // 0.0–1.0
    var negotiationSkill: Double  // 0.0–1.0
    var patienceSeconds: Int
    var customerType: CustomerType
    var dialogue: String
    var photoKey: String          // asset name, e.g. "customer_001"
    var request: CustomerRequest

    // Custom Codable: eski kayıtlarda photoKey yoksa "" kullan
    enum CodingKeys: String, CodingKey {
        case id, name, age, trait, generosity, negotiationSkill
        case patienceSeconds, customerType, dialogue, photoKey, request
    }
    init(id: UUID, name: String, age: Int, trait: String,
         generosity: Double, negotiationSkill: Double, patienceSeconds: Int,
         customerType: CustomerType, dialogue: String,
         photoKey: String = "", request: CustomerRequest) {
        self.id = id; self.name = name; self.age = age; self.trait = trait
        self.generosity = generosity; self.negotiationSkill = negotiationSkill
        self.patienceSeconds = patienceSeconds; self.customerType = customerType
        self.dialogue = dialogue; self.photoKey = photoKey; self.request = request
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        age = try c.decode(Int.self, forKey: .age)
        trait = try c.decode(String.self, forKey: .trait)
        generosity = try c.decode(Double.self, forKey: .generosity)
        negotiationSkill = try c.decode(Double.self, forKey: .negotiationSkill)
        patienceSeconds = try c.decode(Int.self, forKey: .patienceSeconds)
        customerType = try c.decode(CustomerType.self, forKey: .customerType)
        dialogue = try c.decode(String.self, forKey: .dialogue)
        photoKey = (try? c.decode(String.self, forKey: .photoKey)) ?? ""
        request = try c.decode(CustomerRequest.self, forKey: .request)
    }

    static func == (lhs: Customer, rhs: Customer) -> Bool { lhs.id == rhs.id }
}

// MARK: - Transaction

enum TransactionResult: String, Codable {
    case accepted, rejected, bargained, expired
}

// MARK: - Events

enum EventType: String, Codable, CaseIterable {
    case weddingSeason, holiday, touristSeason, promotionWeek, financeNews

    var displayName: String {
        switch self {
        case .weddingSeason:  return "Düğün Sezonu"
        case .holiday:        return "Bayram"
        case .touristSeason:  return "Turist Sezonu"
        case .promotionWeek:  return "Promosyon Haftası"
        case .financeNews:    return "Finans Gündemi"
        }
    }

    var icon: String {
        switch self {
        case .weddingSeason:  return "heart.fill"
        case .holiday:        return "star.fill"
        case .touristSeason:  return "airplane"
        case .promotionWeek:  return "tag.fill"
        case .financeNews:    return "chart.line.uptrend.xyaxis"
        }
    }

    var accentColor: String {
        switch self {
        case .weddingSeason:  return "pink"
        case .holiday:        return "orange"
        case .touristSeason:  return "blue"
        case .promotionWeek:  return "green"
        case .financeNews:    return "red"
        }
    }
}

struct GameEvent: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var eventType: EventType
    var trafficModifier: Double
    var generosityModifier: Double
    var vipModifier: Double
    var durationDays: Int
    var remainingDays: Int
    var isActive: Bool
}

// MARK: - Leaderboard

struct LeaderboardEntry: Identifiable, Codable {
    var id: UUID
    var playerName: String
    var dailyProfit: Double
    var weeklyProfit: Double
    var monthlyRevenue: Double
    var netWorth: Double
    var cashBalance: Double
    var lifestylePoints: Int
    var isPlayer: Bool = false
}
