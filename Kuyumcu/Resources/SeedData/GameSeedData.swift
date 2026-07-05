import Foundation

struct GameSeedData {

    // MARK: - Initial State

    static var initialRates: [Rate] {[
        Rate(name: "Gram Altın",    type: "gramGold",    buyPrice: 4580,  sellPrice: 4620,  sourceName: "nadirgold.com", sourceDate: "16 Mayıs 08:00"),
        Rate(name: "Çeyrek Altın",  type: "quarterGold", buyPrice: 10180, sellPrice: 10220, sourceName: "nadirgold.com", sourceDate: "16 Mayıs 08:00"),
        Rate(name: "Yarım Altın",   type: "halfGold",    buyPrice: 20360, sellPrice: 20440, sourceName: "nadirgold.com", sourceDate: "16 Mayıs 08:00"),
        Rate(name: "Tam Altın",     type: "fullGold",    buyPrice: 40720, sellPrice: 40880, sourceName: "nadirgold.com", sourceDate: "16 Mayıs 08:00"),
        Rate(name: "Dolar",         type: "USD",         buyPrice: 44.80, sellPrice: 45.20, sourceName: "nadirgold.com", sourceDate: "16 Mayıs 08:00"),
        Rate(name: "Euro",          type: "EUR",         buyPrice: 48.80, sellPrice: 49.20, sourceName: "nadirgold.com", sourceDate: "16 Mayıs 08:00"),
    ]}

    static var initialInventory: Inventory {
        Inventory(usd: 10_000, eur: 10_000,
                  gramGold: 150, quarterGold: 100, halfGold: 50, fullGold: 10)
    }

    // MARK: - Lifestyle Items (50 adet, 5 kategori × 10)

    static var allLifestyleItems: [LifestyleItem] {
        // Günlük — oran: ~3.000 TL / puan (sqrt formülü)
        let daily: [LifestyleItem] = [
            LifestyleItem(name: "Espresso Makinesi",     category: .daily,      price:   12_000, lifestylePoints:  2, icon: "cup.and.saucer.fill"),
            LifestyleItem(name: "Kulaklık",              category: .daily,      price:   15_000, lifestylePoints:  2, icon: "headphones"),
            LifestyleItem(name: "PS6",                   category: .daily,      price:   25_000, lifestylePoints:  3, icon: "gamecontroller.fill"),
            LifestyleItem(name: "Drone",                 category: .daily,      price:   35_000, lifestylePoints:  3, icon: "dot.radiowaves.left.and.right"),
            LifestyleItem(name: "Akıllı Telefon",       category: .daily,      price:   45_000, lifestylePoints:  4, icon: "iphone"),
            LifestyleItem(name: "Fotoğraf Makinesi",     category: .daily,      price:   55_000, lifestylePoints:  4, icon: "camera.fill"),
            LifestyleItem(name: "Akıllı TV (85\")",      category: .daily,      price:   60_000, lifestylePoints:  4, icon: "tv.fill"),
            LifestyleItem(name: "Laptop",                category: .daily,      price:   80_000, lifestylePoints:  5, icon: "laptopcomputer"),
            LifestyleItem(name: "Akıllı Ev Sistemi",    category: .daily,      price:  120_000, lifestylePoints:  6, icon: "house.circle.fill"),
            LifestyleItem(name: "Kol Saati",             category: .daily,      price:  150_000, lifestylePoints:  7, icon: "watchface.applewatch.case"),
        ]
        // Taşıt — oran: ~80.000 TL / puan (sqrt formülü)
        let vehicle: [LifestyleItem] = [
            LifestyleItem(name: "Bisiklet",              category: .vehicle,    price:   20_000, lifestylePoints:  1, icon: "bicycle"),
            LifestyleItem(name: "Motosiklet",            category: .vehicle,    price:  200_000, lifestylePoints:  2, icon: "bicycle.circle.fill"),
            LifestyleItem(name: "Bütçe Araç",            category: .vehicle,    price:  600_000, lifestylePoints:  3, icon: "car.fill"),
            LifestyleItem(name: "Orta Sınıf Araç",       category: .vehicle,    price:1_500_000, lifestylePoints:  4, icon: "car.fill"),
            LifestyleItem(name: "SUV",                   category: .vehicle,    price:3_000_000, lifestylePoints:  6, icon: "car.fill"),
            LifestyleItem(name: "Tekne",                 category: .vehicle,    price:8_000_000, lifestylePoints: 10, icon: "sailboat.fill"),
            LifestyleItem(name: "Lüks Sedan",            category: .vehicle,    price:10_000_000, lifestylePoints:  9, icon: "car.fill"),
            LifestyleItem(name: "Spor Araba",            category: .vehicle,    price:12_000_000, lifestylePoints: 12, icon: "car.fill"),
            LifestyleItem(name: "Yat",                   category: .vehicle,    price:50_000_000, lifestylePoints: 22, icon: "sailboat.fill"),
            LifestyleItem(name: "Helikopter",            category: .vehicle,    price:100_000_000, lifestylePoints: 32, icon: "airplane"),
        ]
        // Gayrimenkul — oran: ~500.000 TL / puan (sqrt formülü)
        let realEstate: [LifestyleItem] = [
            LifestyleItem(name: "Stüdyo Daire",          category: .realEstate, price: 2_500_000, lifestylePoints:  2, icon: "building.fill"),
            LifestyleItem(name: "1+1 Daire",             category: .realEstate, price: 4_000_000, lifestylePoints:  3, icon: "building.fill"),
            LifestyleItem(name: "2+1 Apartman Dairesi",  category: .realEstate, price: 7_000_000, lifestylePoints:  4, icon: "building.2.fill"),
            LifestyleItem(name: "3+1 Geniş Daire",       category: .realEstate, price:12_000_000, lifestylePoints:  5, icon: "building.2.fill"),
            LifestyleItem(name: "Lüks Site Dairesi",     category: .realEstate, price:20_000_000, lifestylePoints:  6, icon: "building.2.crop.circle.fill"),
            LifestyleItem(name: "Villa",                 category: .realEstate, price:35_000_000, lifestylePoints:  8, icon: "house.fill"),
            LifestyleItem(name: "Tripleks",              category: .realEstate, price:55_000_000, lifestylePoints: 10, icon: "house.fill"),
            LifestyleItem(name: "Villa Sitesi",          category: .realEstate, price:80_000_000, lifestylePoints: 13, icon: "house.circle.fill"),
            LifestyleItem(name: "Köşk",                  category: .realEstate, price:150_000_000, lifestylePoints: 17, icon: "building.columns.fill"),
            LifestyleItem(name: "Malikane",              category: .realEstate, price:300_000_000, lifestylePoints: 24, icon: "building.columns.fill"),
        ]
        // Lüks — oran: ~20.000 TL / puan (sqrt formülü)
        let luxury: [LifestyleItem] = [
            LifestyleItem(name: "Tasarım Güneş Gözlüğü",category: .luxury,     price:   30_000, lifestylePoints:  1, icon: "eyeglasses"),
            LifestyleItem(name: "Özel Takım Elbise",     category: .luxury,     price:  150_000, lifestylePoints:  3, icon: "person.fill"),
            LifestyleItem(name: "Lüks El Çantası",       category: .luxury,     price:  200_000, lifestylePoints:  3, icon: "bag.fill"),
            LifestyleItem(name: "Kürk Kaban",            category: .luxury,     price:  400_000, lifestylePoints:  4, icon: "person.crop.circle.badge.checkmark"),
            LifestyleItem(name: "Pırlanta Kolye",        category: .luxury,     price:  500_000, lifestylePoints:  5, icon: "sparkles"),
            LifestyleItem(name: "Özel Şarap Koleksiyonu",category: .luxury,     price:  800_000, lifestylePoints:  6, icon: "wineglass.fill"),
            LifestyleItem(name: "VIP Kulüp Üyeliği",    category: .luxury,     price:1_000_000, lifestylePoints:  7, icon: "crown.fill"),
            LifestyleItem(name: "İsviçre Saati",         category: .luxury,     price:1_500_000, lifestylePoints:  9, icon: "watchface.applewatch.case"),
            LifestyleItem(name: "Sanat Eseri",           category: .luxury,     price:3_000_000, lifestylePoints: 12, icon: "photo.artframe"),
            LifestyleItem(name: "Private Jet Payı",      category: .luxury,     price:20_000_000, lifestylePoints: 32, icon: "airplane.circle.fill"),
        ]
        // Deneyim — oran: ~8.000 TL / puan (sqrt formülü)
        let experience: [LifestyleItem] = [
            LifestyleItem(name: "Yurt İçi Tatil",        category: .experience, price:   50_000, lifestylePoints:  2, icon: "beach.umbrella.fill"),
            LifestyleItem(name: "Dalış Kursu",           category: .experience, price:   60_000, lifestylePoints:  3, icon: "drop.fill"),
            LifestyleItem(name: "Michelin Yıldızlı Akşam",category: .experience,price:   80_000, lifestylePoints:  3, icon: "fork.knife"),
            LifestyleItem(name: "Özel Konser Koltuğu",   category: .experience, price:  150_000, lifestylePoints:  4, icon: "music.note"),
            LifestyleItem(name: "Avrupa Turu",           category: .experience, price:  200_000, lifestylePoints:  5, icon: "airplane"),
            LifestyleItem(name: "Dubai Tatili",          category: .experience, price:  400_000, lifestylePoints:  7, icon: "sun.max.fill"),
            LifestyleItem(name: "F1 Yarışı",             category: .experience, price:  500_000, lifestylePoints:  8, icon: "flag.checkered"),
            LifestyleItem(name: "Maldivler",             category: .experience, price:  800_000, lifestylePoints: 10, icon: "water.waves"),
            LifestyleItem(name: "Dünya Turu",            category: .experience, price:3_000_000, lifestylePoints: 19, icon: "globe.europe.africa.fill"),
            LifestyleItem(name: "Uzay Yolculuğu",        category: .experience, price:500_000_000, lifestylePoints: 250, icon: "sparkle"),
        ]
        return daily + vehicle + realEstate + luxury + experience
    }

    // MARK: - Shops

    static var allShops: [Shop] {[
        Shop(id: UUID(), key: "neighborhood_shop", name: "Mahalle Kuyumcusu",
             description: "Sıradan bir başlangıç.",
             locationType: .neighborhood, level: 1,
             purchasePrice: 0,
             customerTrafficMultiplier: 1.0,
             vipChance: 0.05, employeeCapacity: 2, employeeCount: 0, isOwned: true),

        Shop(id: UUID(), key: "bazaar_shop", name: "Çarşı Kuyumcusu",
             description: "Alışverişin tam kalbinde.",
             locationType: .bazaar, level: 1,
             purchasePrice: 5_000_000,
             customerTrafficMultiplier: 1.5,
             vipChance: 0.10, employeeCapacity: 4, employeeCount: 0, isOwned: false),

        Shop(id: UUID(), key: "district_bazaar_shop", name: "İlçe Kuyumcusu",
             description: "İlçenin güvenilir kuyumcusu.",
             locationType: .districtBazaar, level: 1,
             purchasePrice: 10_000_000,
             customerTrafficMultiplier: 2.0,
             vipChance: 0.15, employeeCapacity: 6, employeeCount: 0, isOwned: false),

        Shop(id: UUID(), key: "city_center_shop", name: "Şehir Merkezi Kuyumcusu",
             description: "Büyük adımlar, büyük kazançlar.",
             locationType: .cityCenter, level: 1,
             purchasePrice: 15_000_000,
             customerTrafficMultiplier: 2.5,
             vipChance: 0.20, employeeCapacity: 8, employeeCount: 0, isOwned: false),

        Shop(id: UUID(), key: "mall_shop", name: "AVM Kuyumcusu",
             description: "Prestijin yeni adresi.",
             locationType: .mall, level: 1,
             purchasePrice: 25_000_000,
             customerTrafficMultiplier: 3.0,
             vipChance: 0.25, employeeCapacity: 10, employeeCount: 0, isOwned: false),

        Shop(id: UUID(), key: "grand_bazaar_shop", name: "Kapalıçarşı Kuyumcusu",
             description: "Bu işin merkezi.",
             locationType: .grandBazaar, level: 1,
             purchasePrice: 50_000_000,
             customerTrafficMultiplier: 5.0,
             vipChance: 0.30, employeeCapacity: 12, employeeCount: 0, isOwned: false),
    ]}

    static func shop(forKey key: String?) -> Shop? {
        guard let key else { return nil }
        return allShops.first(where: { $0.key == key })
    }

    // MARK: - Events

    // Etkinlikler Supabase'den yükleniyor (game_events tablosu)
    static var allEvents: [GameEvent] { [] }

    // MARK: - Customer Templates

    static var customerTemplates: [Customer] {[
        Customer(id: UUID(), name: "Ayşe Yılmaz", age: 56, trait: "Tutumlu",
                 generosity: 0.30, negotiationSkill: 0.70, patienceSeconds: 45,
                 customerType: .urgent,
                 dialogue: "Merhaba ustam. Oğlumun düğünü için 5 adet tam altın almak istiyorum. İyi fiyat verir misiniz?",
                 request: CustomerRequest(id: UUID(), direction: .customerBuysFromPlayer, items: [
                    RequestItem(productCategory: .goldFull, quantity: 5, label: "5 Tam Altın")
                 ])),

        Customer(id: UUID(), name: "Mehmet Kaya", age: 43, trait: "Pazarlıkçı",
                 generosity: 0.40, negotiationSkill: 0.90, patienceSeconds: 60,
                 customerType: .frugal,
                 dialogue: "Kolay gelsin. Elimde 12 çeyrek, 6 yarım, 2 tam var. Ne kadara bozarsınız?",
                 request: CustomerRequest(id: UUID(), direction: .customerSellsToPlayer, items: [
                    RequestItem(productCategory: .goldQuarter, quantity: 12, label: "12 Çeyrek Altın"),
                    RequestItem(productCategory: .goldHalf,    quantity: 6,  label: "6 Yarım Altın"),
                    RequestItem(productCategory: .goldFull,    quantity: 2,  label: "2 Tam Altın"),
                 ])),

        Customer(id: UUID(), name: "Anna Müller", age: 34, trait: "Turist",
                 generosity: 0.60, negotiationSkill: 0.30, patienceSeconds: 40,
                 customerType: .tourist,
                 dialogue: "Hello! I want to exchange 800 Euro to Turkish lira. Good rate please!",
                 request: CustomerRequest(id: UUID(), direction: .customerSellsToPlayer, items: [
                    RequestItem(productCategory: .currencyEUR, quantity: 800, label: "800 Euro")
                 ])),

        Customer(id: UUID(), name: "Cem Arslan", age: 38, trait: "Yatırımcı",
                 generosity: 0.50, negotiationSkill: 0.80, patienceSeconds: 70,
                 customerType: .regular,
                 dialogue: "Bugün 100 gram altın almak istiyorum. İyi fiyat verirseniz sürekli gelirim.",
                 request: CustomerRequest(id: UUID(), direction: .customerBuysFromPlayer, items: [
                    RequestItem(productCategory: .goldGram, quantity: 100, label: "100 Gram Altın")
                 ])),

        Customer(id: UUID(), name: "Fatma Demir", age: 61, trait: "Temkinli",
                 generosity: 0.35, negotiationSkill: 0.60, patienceSeconds: 50,
                 customerType: .frugal,
                 dialogue: "Elimde 3 bilezik var, toplam 45 gram geliyor. Bozdurmak istiyorum.",
                 request: CustomerRequest(id: UUID(), direction: .customerSellsToPlayer, items: [
                    RequestItem(productCategory: .jewelry, quantity: 45, label: "45 Gram Altın (Bilezik)")
                 ])),

        Customer(id: UUID(), name: "Hasan Bey", age: 52, trait: "Cömert",
                 generosity: 0.80, negotiationSkill: 0.40, patienceSeconds: 55,
                 customerType: .generous,
                 dialogue: "Kızıma nişan hediyesi almak istiyorum. Güzel bir bilezik olsun.",
                 request: CustomerRequest(id: UUID(), direction: .customerBuysFromPlayer, items: [
                    RequestItem(productCategory: .jewelry, quantity: 20, label: "20 Gram Altın (Bilezik)")
                 ])),

        Customer(id: UUID(), name: "Kemal Bey", age: 48, trait: "Normal",
                 generosity: 0.55, negotiationSkill: 0.55, patienceSeconds: 50,
                 customerType: .regular,
                 dialogue: "Elimde 500 dolar var, bozdurmak istiyorum.",
                 request: CustomerRequest(id: UUID(), direction: .customerSellsToPlayer, items: [
                    RequestItem(productCategory: .currencyUSD, quantity: 500, label: "500 Dolar")
                 ])),

        Customer(id: UUID(), name: "VIP Müşteri", age: 45, trait: "Premium",
                 generosity: 0.90, negotiationSkill: 0.70, patienceSeconds: 90,
                 customerType: .vip,
                 dialogue: "Sizinle çalışmak istiyorum. 10 tam altın alacağım, iyi bir fiyat bekliyorum.",
                 request: CustomerRequest(id: UUID(), direction: .customerBuysFromPlayer, items: [
                    RequestItem(productCategory: .goldFull, quantity: 10, label: "10 Tam Altın"),
                 ])),

        Customer(id: UUID(), name: "Zeynep Hanım", age: 29, trait: "Acele",
                 generosity: 0.65, negotiationSkill: 0.45, patienceSeconds: 30,
                 customerType: .regular,
                 dialogue: "Çeyrek almak istiyorum, 3 tane. Çok vaktim yok.",
                 request: CustomerRequest(id: UUID(), direction: .customerBuysFromPlayer, items: [
                    RequestItem(productCategory: .goldQuarter, quantity: 3, label: "3 Çeyrek Altın")
                 ])),

        Customer(id: UUID(), name: "Marco Rossi", age: 41, trait: "Turist",
                 generosity: 0.70, negotiationSkill: 0.25, patienceSeconds: 35,
                 customerType: .tourist,
                 dialogue: "Ciao! I want to buy some gold. Maybe 5 gram gold? Istanbul souvenir!",
                 request: CustomerRequest(id: UUID(), direction: .customerBuysFromPlayer, items: [
                    RequestItem(productCategory: .goldGram, quantity: 5, label: "5 Gram Altın")
                 ])),
    ]}

    // MARK: - Shop-aware Customer Generation

    /// Dükkan lokasyonuna göre CustomerLibrary üzerinden müşteri kuyruğu oluşturur.
    static func generateCustomerQueue(count: Int, for locationType: ShopLocationType = .neighborhood) -> [Customer] {
        return (0..<count).map { _ in CustomerLibrary.generateCustomer(for: locationType) }
    }
}
