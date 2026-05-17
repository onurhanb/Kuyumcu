import Foundation

// MARK: - Customer Profile (static data)

struct CustomerProfile {
    let name: String
    let age: Int
    let trait: String
    let customerType: CustomerType
    let photoKey: String   // e.g. "customer_001"
}

// MARK: - Customer Library

enum CustomerLibrary {

    // MARK: - Quantity Range by Location

    static func quantityRange(for loc: ShopLocationType) -> ClosedRange<Int> {
        switch loc {
        case .neighborhood:   return 1...8
        case .bazaar:         return 2...15
        case .districtBazaar: return 3...25
        case .cityCenter:     return 5...35
        case .mall:           return 8...50
        case .grandBazaar:    return 10...60
        }
    }

    // MARK: - 60 Profiles (10 per type)

    static let allProfiles: [CustomerProfile] = [
        // Normal (001–010)
        CustomerProfile(name: "Kemal Arslan",    age: 49, trait: "Normal",      customerType: .regular, photoKey: "customer_001"),
        CustomerProfile(name: "Zeynep Şahin",    age: 35, trait: "Normal",      customerType: .regular, photoKey: "customer_002"),
        CustomerProfile(name: "Kadir Usta",      age: 58, trait: "Normal",      customerType: .regular, photoKey: "customer_003"),
        CustomerProfile(name: "Burak Bey",       age: 32, trait: "Normal",      customerType: .regular, photoKey: "customer_004"),
        CustomerProfile(name: "Necati Bey",      age: 50, trait: "Normal",      customerType: .regular, photoKey: "customer_005"),
        CustomerProfile(name: "Huriye Hanım",    age: 60, trait: "Normal",      customerType: .regular, photoKey: "customer_006"),
        CustomerProfile(name: "Nilüfer Hanım",   age: 42, trait: "Normal",      customerType: .regular, photoKey: "customer_007"),
        CustomerProfile(name: "Mustafa Usta",    age: 62, trait: "Normal",      customerType: .regular, photoKey: "customer_008"),
        CustomerProfile(name: "Cengiz Bey",      age: 44, trait: "Normal",      customerType: .regular, photoKey: "customer_009"),
        CustomerProfile(name: "Ferdi Bey",       age: 40, trait: "Normal",      customerType: .regular, photoKey: "customer_010"),
        // Tutumlu (011–020)
        CustomerProfile(name: "Mehmet Kaya",     age: 43, trait: "Pazarlıkçı",  customerType: .frugal,  photoKey: "customer_011"),
        CustomerProfile(name: "Fatma Öztürk",    age: 52, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_012"),
        CustomerProfile(name: "Emine Hanım",     age: 71, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_013"),
        CustomerProfile(name: "Tuncay Bey",      age: 37, trait: "Pazarlıkçı",  customerType: .frugal,  photoKey: "customer_014"),
        CustomerProfile(name: "Sinan Usta",      age: 45, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_015"),
        CustomerProfile(name: "Müzeyyen Hanım",  age: 73, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_016"),
        CustomerProfile(name: "Tahsin Bey",      age: 55, trait: "Pazarlıkçı",  customerType: .frugal,  photoKey: "customer_017"),
        CustomerProfile(name: "Nazmiye Hanım",   age: 64, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_018"),
        CustomerProfile(name: "Necla Hanım",     age: 56, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_019"),
        CustomerProfile(name: "Hüseyin Bey",     age: 59, trait: "Tutumlu",     customerType: .frugal,  photoKey: "customer_020"),
        // Cömert (021–030)
        CustomerProfile(name: "Hasan Demir",     age: 61, trait: "Cömert",      customerType: .generous, photoKey: "customer_021"),
        CustomerProfile(name: "Gülay Hanım",     age: 46, trait: "Cömert",      customerType: .generous, photoKey: "customer_022"),
        CustomerProfile(name: "Orhan Bey",       age: 54, trait: "Cömert",      customerType: .generous, photoKey: "customer_023"),
        CustomerProfile(name: "Suat Bey",        age: 57, trait: "Cömert",      customerType: .generous, photoKey: "customer_024"),
        CustomerProfile(name: "Şaziye Hanım",    age: 67, trait: "Cömert",      customerType: .generous, photoKey: "customer_025"),
        CustomerProfile(name: "Salih Bey",       age: 47, trait: "Cömert",      customerType: .generous, photoKey: "customer_026"),
        CustomerProfile(name: "Mehtap Hanım",    age: 43, trait: "Cömert",      customerType: .generous, photoKey: "customer_027"),
        CustomerProfile(name: "Rıfat Bey",       age: 51, trait: "Cömert",      customerType: .generous, photoKey: "customer_028"),
        CustomerProfile(name: "İsmail Bey",      age: 65, trait: "Cömert",      customerType: .generous, photoKey: "customer_029"),
        CustomerProfile(name: "Leyla Hanım",     age: 36, trait: "Cömert",      customerType: .generous, photoKey: "customer_030"),
        // Acil (031–040)
        CustomerProfile(name: "Ersin Bey",       age: 34, trait: "Acele",       customerType: .urgent,  photoKey: "customer_031"),
        CustomerProfile(name: "Melike Hanım",    age: 38, trait: "Acele",       customerType: .urgent,  photoKey: "customer_032"),
        CustomerProfile(name: "Adem Bey",        age: 29, trait: "Acele",       customerType: .urgent,  photoKey: "customer_033"),
        CustomerProfile(name: "Selin Hanım",     age: 26, trait: "Acele",       customerType: .urgent,  photoKey: "customer_034"),
        CustomerProfile(name: "Tarık Bey",       age: 41, trait: "Acele",       customerType: .urgent,  photoKey: "customer_035"),
        CustomerProfile(name: "Nurgül Hanım",    age: 33, trait: "Acele",       customerType: .urgent,  photoKey: "customer_036"),
        CustomerProfile(name: "Onur Bey",        age: 28, trait: "Acele",       customerType: .urgent,  photoKey: "customer_037"),
        CustomerProfile(name: "Ebru Hanım",      age: 45, trait: "Acele",       customerType: .urgent,  photoKey: "customer_038"),
        CustomerProfile(name: "Mert Bey",        age: 31, trait: "Acele",       customerType: .urgent,  photoKey: "customer_039"),
        CustomerProfile(name: "Deniz Hanım",     age: 27, trait: "Acele",       customerType: .urgent,  photoKey: "customer_040"),
        // Turist (041–050)
        CustomerProfile(name: "Anna Müller",     age: 34, trait: "Turist",      customerType: .tourist, photoKey: "customer_041"),
        CustomerProfile(name: "Marco Rossi",     age: 29, trait: "Turist",      customerType: .tourist, photoKey: "customer_042"),
        CustomerProfile(name: "Sarah Johnson",   age: 27, trait: "Turist",      customerType: .tourist, photoKey: "customer_043"),
        CustomerProfile(name: "Chen Wei",        age: 31, trait: "Turist",      customerType: .tourist, photoKey: "customer_044"),
        CustomerProfile(name: "David Miller",    age: 25, trait: "Turist",      customerType: .tourist, photoKey: "customer_045"),
        CustomerProfile(name: "Aisha Rahman",    age: 28, trait: "Turist",      customerType: .tourist, photoKey: "customer_046"),
        CustomerProfile(name: "Lena Schmidt",    age: 32, trait: "Turist",      customerType: .tourist, photoKey: "customer_047"),
        CustomerProfile(name: "James Wilson",    age: 38, trait: "Turist",      customerType: .tourist, photoKey: "customer_048"),
        CustomerProfile(name: "Yuki Tanaka",     age: 24, trait: "Turist",      customerType: .tourist, photoKey: "customer_049"),
        CustomerProfile(name: "Sofia Rodriguez", age: 30, trait: "Turist",      customerType: .tourist, photoKey: "customer_050"),
        // VIP (051–060)
        CustomerProfile(name: "Ali Bey",         age: 55, trait: "Premium",     customerType: .vip,     photoKey: "customer_051"),
        CustomerProfile(name: "Neslihan Hanım",  age: 41, trait: "Premium",     customerType: .vip,     photoKey: "customer_052"),
        CustomerProfile(name: "Yusuf Bey",       age: 50, trait: "Premium",     customerType: .vip,     photoKey: "customer_053"),
        CustomerProfile(name: "Kamuran Hanım",   age: 45, trait: "Premium",     customerType: .vip,     photoKey: "customer_054"),
        CustomerProfile(name: "Murat Bey",       age: 56, trait: "Premium",     customerType: .vip,     photoKey: "customer_055"),
        CustomerProfile(name: "Halime Hanım",    age: 58, trait: "Premium",     customerType: .vip,     photoKey: "customer_056"),
        CustomerProfile(name: "Rıza Bey",        age: 67, trait: "Premium",     customerType: .vip,     photoKey: "customer_057"),
        CustomerProfile(name: "Kâzım Bey",       age: 52, trait: "Premium",     customerType: .vip,     photoKey: "customer_058"),
        CustomerProfile(name: "İbrahim Efendi",  age: 63, trait: "Premium",     customerType: .vip,     photoKey: "customer_059"),
        CustomerProfile(name: "Şükrü Bey",       age: 69, trait: "Premium",     customerType: .vip,     photoKey: "customer_060"),
    ]

    // MARK: - Dialogue Templates (100+)
    // {A}=miktar1, {B}=ürün1, {C}=miktar2, {D}=ürün2

    // Müşteri satın alıyor – 1 ürün (30 şablon)
    private static let buyTemplates1: [String] = [
        "Selamünaleyküm usta. {A} adet {B} almak istiyorum.",
        "Kolay gelsin. {A} {B} var mı elinizde?",
        "Merhaba. Yatırım amaçlı {A} {B} almak istiyorum. En iyi fiyat nedir?",
        "Kolay gelsin usta. Kızımın çeyizi için {A} {B} lazım.",
        "Bir arkadaşım tavsiye etti. {A} adet {B} almak istiyorum.",
        "Selamlar. Düğün için {A} {B} alacağım, fiyat ne kadar?",
        "Ustam, bugün {A} {B} almak niyetindeyim. Müsaitseniz bakalım.",
        "Merhaba! {A} {B} almak istiyorum, iyi fiyat verir misiniz?",
        "{A} tane {B} ne kadar yapar?",
        "Kolay gelsin. Annem için {A} {B} hediye alacağım.",
        "Selamünaleyküm. {A} {B} bakar mısınız, ne fiyata denk gelir?",
        "Günaydın. {A} adet {B} almak istiyorum.",
        "Hayırlı işler usta. {A} {B} almayı düşünüyorum, fiyat eder mi?",
        "Efendim, nişan için {A} {B} almam lazım.",
        "Selam. Doğum günü hediyesi olarak {A} {B} düşünüyorum.",
        "Ustam, {A} {B} alırsam iyi fiyat verir misiniz?",
        "Merhaba. Tasarruf amacıyla {A} {B} almak istiyorum.",
        "Kolay gelsin. {A} {B} var mı, stok durumunuz nasıl?",
        "Selamlar usta. Bayram hediyesi için {A} {B} alacağım.",
        "{A} adet {B} istiyorum. En uygun fiyat ne olur?",
        "Ustam merhaba. {A} {B} almak istiyorum, müsait misiniz?",
        "Hayırlı günler. Oğlumun düğünü için {A} {B} lazım.",
        "Kolay gelsin. {A} {B} almak istiyorum, tavsiyeniz var mı?",
        "Efendim, {A} {B} satın almak istiyorum.",
        "Selam. {A} {B} bakalım, kaç para?",
        "Merhaba. Emekliliğim için {A} {B} almak istiyorum.",
        "Ustam, {A} {B} alacağım. Kaliteli mal mı?",
        "Günaydın. Kocama sürpriz için {A} {B} istiyorum.",
        "Selamünaleyküm. {A} {B} almak için geldim.",
        "Kolay gelsin. {A} adet {B} istiyorum, uygun fiyat var mı?",
    ]

    // Müşteri satın alıyor – 2 ürün (20 şablon)
    private static let buyTemplates2: [String] = [
        "Kolay gelsin. {A} {B} ve {C} {D} almak istiyorum.",
        "Düğün için {A} {B} ile {C} {D} lazım. Fiyat nedir?",
        "Selamünaleyküm usta. {A} {B} ve {C} {D} toplam ne tutar?",
        "Merhaba! {A} {B} ve {C} {D} almak istiyorum, paket fiyat olur mu?",
        "Kolay gelsin. Birden fazla alacağım: {A} {B} ve {C} {D}.",
        "Ustam, {A} {B} ile {C} {D} beraberinde alırsam indirim yapar mısınız?",
        "Nişan takısı için {A} {B} ve {C} {D} istiyorum.",
        "Selam. {A} {B} ve {C} {D} almak istiyorum.",
        "Merhaba. Yatırım için {A} {B} ve {C} {D} alacağım.",
        "Kolay gelsin usta. {A} {B} ile {C} {D} almak niyetindeyim.",
        "Efendim, {A} {B} ve {C} {D} stokta var mı?",
        "Selamlar. {A} {B} ile beraber {C} {D} alırsam fiyat ne olur?",
        "Hayırlı işler. Birlikte {A} {B} ve {C} {D} alacağım.",
        "Merhaba, {A} {B} ve {C} {D} almak için fiyat soruyorum.",
        "Usta, {A} {B} ve {C} {D} için en iyi teklif nedir?",
        "Kolay gelsin. Hem {A} {B} hem de {C} {D} lazım bana.",
        "Selam. {A} {B} ve {C} {D} toplam fiyatı nedir?",
        "Selamünaleyküm. {A} {B} ile {C} {D} alacağım, müsaitseniz.",
        "Merhaba usta. Çeyiz için {A} {B} ve {C} {D} istiyorum.",
        "Kolay gelsin. {A} {B} ve {C} {D} için teklifiniz nedir?",
    ]

    // Müşteri satıyor – 1 ürün (30 şablon)
    private static let sellTemplates1: [String] = [
        "Kolay gelsin usta. Elimde {A} adet {B} var, ne fiyata alırsınız?",
        "Merhaba. {A} {B} bozdurmak istiyorum.",
        "Selamünaleyküm. Elimdeki {A} {B}'yi size satmak istiyorum.",
        "{A} {B} var elimde. Kaç para eder?",
        "Ustam merhaba. {A} adet {B} satmak istiyorum.",
        "Kolay gelsin. {A} {B} almak ister misiniz?",
        "Merhaba. Nakit lazım, {A} {B} satmak istiyorum.",
        "Selamlar usta. {A} {B} var, bozar mısınız?",
        "Efendim, {A} adet {B} satmaya geldim.",
        "Günaydın. {A} {B} satmak istiyorum, kaç para verirsiniz?",
        "Elimde {A} {B} var. Alır mısınız?",
        "Ustam, {A} {B} satmak istiyorum. Bugün fiyat nasıl?",
        "Merhaba. {A} {B} satacağım, ne kadar eder?",
        "Kolay gelsin. {A} {B} bozdurmaya geldim.",
        "Selamünaleyküm. {A} adet {B} var elimde, almak ister misiniz?",
        "Selam usta. Nakit sıkıntısı var, {A} {B} satacağım.",
        "Merhaba. {A} {B}'yi değerlendirmek istiyorum.",
        "{A} {B} ne fiyata alırsın?",
        "Kolay gelsin. {A} {B} elinizden geçiyor mu?",
        "Ustam, {A} adet {B} satmak istiyorum, fiyat?",
        "Merhaba. {A} {B} var, bugün al mısınız?",
        "Selamlar. {A} {B} almak ister misiniz?",
        "Efendim, {A} {B} satacağım. En iyi fiyat ne olur?",
        "Kolay gelsin. {A} {B} bozdurabilir miyim?",
        "Merhaba. {A} adet {B} satmak niyetindeyim.",
        "Usta merhaba. {A} {B} var, kaç para eder bende?",
        "Selam. {A} {B} satacağım, teklifin ne?",
        "Günaydın. {A} {B} bozdurabilir miyim?",
        "Kolay gelsin usta. {A} {B}'leri satmak istiyorum.",
        "Selamünaleyküm. {A} adet {B} almak ister misiniz?",
    ]

    // Müşteri satıyor – 2 ürün (20 şablon)
    private static let sellTemplates2: [String] = [
        "Kolay gelsin. Elimde {A} {B} ve {C} {D} var, toplam ne verirsiniz?",
        "Merhaba. {A} {B} ile {C} {D} satmak istiyorum.",
        "Selamünaleyküm usta. {A} {B} ve {C} {D} bozar mısınız?",
        "{A} {B} ve {C} {D} var. Kaç para eder?",
        "Ustam, {A} {B} ile {C} {D} almak ister misiniz?",
        "Merhaba. Nakit lazım, {A} {B} ve {C} {D} satacağım.",
        "Kolay gelsin. {A} {B} ve {C} {D} var, toptan alır mısınız?",
        "Selamlar. {A} {B} ile {C} {D} için en iyi fiyat nedir?",
        "Efendim, {A} {B} ve {C} {D} satmaya geldim.",
        "Günaydın usta. {A} {B} ve {C} {D} bozdurabilir miyim?",
        "{A} {B} ve {C} {D} almak ister misiniz?",
        "Merhaba. {A} {B} ile {C} {D} değerlendirmek istiyorum.",
        "Selamünaleyküm. {A} {B} ve {C} {D} var elimde.",
        "Kolay gelsin. {A} {B} ve {C} {D} için teklifiniz?",
        "Ustam, {A} {B} ve {C} {D} satacağım, müsait misiniz?",
        "Selam. {A} {B} ile {C} {D}'yi bozdurabilir miyim?",
        "Merhaba usta. {A} {B} ve {C} {D} var, ne verirsiniz?",
        "Kolay gelsin. {A} {B} ile {C} {D} almak ister misiniz?",
        "Selamlar. {A} {B} ve {C} {D} satmak istiyorum.",
        "Merhaba efendim. {A} {B} ile {C} {D} için fiyat nedir?",
    ]

    // MARK: - Preferred Categories by Type

    private static func preferredBuyCategories(for type: CustomerType) -> [ProductCategory] {
        switch type {
        case .regular:  return [.goldGram, .goldQuarter, .goldHalf, .goldFull]
        case .frugal:   return [.goldGram, .goldQuarter, .goldHalf]
        case .generous: return [.goldGram, .goldQuarter, .goldFull, .jewelry]
        case .urgent:   return [.goldGram, .goldQuarter, .jewelry]
        case .tourist:  return [.goldGram, .jewelry]
        case .vip:      return [.goldFull, .jewelry, .goldGram]
        }
    }

    private static func preferredSellCategories(for type: CustomerType) -> [ProductCategory] {
        switch type {
        case .regular:  return [.goldGram, .goldQuarter, .goldHalf, .currencyUSD, .currencyEUR]
        case .frugal:   return [.goldGram, .goldQuarter, .currencyUSD]
        case .generous: return [.goldGram, .goldQuarter, .goldHalf]
        case .urgent:   return [.goldGram, .goldQuarter, .currencyUSD]
        case .tourist:  return [.currencyUSD, .currencyEUR]
        case .vip:      return [.goldFull, .goldGram, .jewelry]
        }
    }

    // MARK: - Display Labels

    private static func displayLabel(for cat: ProductCategory) -> String {
        switch cat {
        case .goldGram:    return "gram altın"
        case .goldQuarter: return "çeyrek altın"
        case .goldHalf:    return "yarım altın"
        case .goldFull:    return "tam altın"
        case .currencyUSD: return "Dolar"
        case .currencyEUR: return "Euro"
        case .jewelry:     return "gram altın (bilezik)"
        }
    }

    private static func requestLabel(qty: Int, cat: ProductCategory) -> String {
        switch cat {
        case .goldGram:    return "\(qty) Gram Altın"
        case .goldQuarter: return "\(qty) Çeyrek Altın"
        case .goldHalf:    return "\(qty) Yarım Altın"
        case .goldFull:    return "\(qty) Tam Altın"
        case .currencyUSD: return "\(qty) Dolar"
        case .currencyEUR: return "\(qty) Euro"
        case .jewelry:     return "\(qty) Gram Altın (Bilezik)"
        }
    }

    // MARK: - Behaviour Parameters
    // Normal:   60s   — standart beklenti
    // Tutumlu: 120s   — uzun süre bekler, fiyata çok duyarlı
    // Cömert:   60s   — fiyata esnek, cömert
    // Acil:     45s   — fiyata esnek, beklemez
    // Turist:   60s   — fiyata esnek, müzakere yapmaz
    // VIP:      45s   — en iyi fiyat, en iyi teklif, beklemez

    private static func generosity(for type: CustomerType) -> Double {
        switch type {
        case .regular:  return Double.random(in: 0.45...0.65)
        case .frugal:   return Double.random(in: 0.25...0.40)
        case .generous: return Double.random(in: 0.70...0.90)
        case .urgent:   return Double.random(in: 0.55...0.70)
        case .tourist:  return Double.random(in: 0.60...0.75)
        case .vip:      return Double.random(in: 0.85...0.95)
        }
    }

    private static func negotiationSkill(for type: CustomerType) -> Double {
        switch type {
        case .regular:  return Double.random(in: 0.40...0.60)
        case .frugal:   return Double.random(in: 0.75...0.95)
        case .generous: return Double.random(in: 0.20...0.40)
        case .urgent:   return Double.random(in: 0.25...0.45)
        case .tourist:  return Double.random(in: 0.15...0.35)
        case .vip:      return Double.random(in: 0.60...0.80)
        }
    }

    private static func patience(for type: CustomerType) -> Int {
        switch type {
        case .regular:  return Int.random(in: 55...65)   // ~60s
        case .frugal:   return Int.random(in: 110...130) // ~120s
        case .generous: return Int.random(in: 55...65)   // ~60s
        case .urgent:   return Int.random(in: 40...50)   // ~45s
        case .tourist:  return Int.random(in: 55...65)   // ~60s
        case .vip:      return Int.random(in: 40...50)   // ~45s
        }
    }

    // MARK: - Direction Probability

    private static func pickDirection(for type: CustomerType) -> TransactionDirection {
        let buyProb: Double
        switch type {
        case .regular:  buyProb = 0.55
        case .frugal:   buyProb = 0.50
        case .generous: buyProb = 0.65
        case .urgent:   buyProb = 0.55
        case .tourist:  buyProb = 0.40
        case .vip:      buyProb = 0.70
        }
        return Double.random(in: 0...1) < buyProb ? .customerBuysFromPlayer : .customerSellsToPlayer
    }

    // MARK: - Profile Weights by Location

    private static func typeWeights(for loc: ShopLocationType) -> [CustomerType: Double] {
        switch loc {
        case .neighborhood:
            return [.regular: 4, .frugal: 3, .generous: 1, .urgent: 2, .tourist: 0, .vip: 0]
        case .bazaar:
            return [.regular: 3, .frugal: 2, .generous: 2, .urgent: 2, .tourist: 1, .vip: 0]
        case .districtBazaar:
            return [.regular: 3, .frugal: 2, .generous: 2, .urgent: 2, .tourist: 1, .vip: 1]
        case .cityCenter:
            return [.regular: 2, .frugal: 1, .generous: 2, .urgent: 2, .tourist: 2, .vip: 1]
        case .mall:
            return [.regular: 2, .frugal: 1, .generous: 2, .urgent: 1, .tourist: 3, .vip: 2]
        case .grandBazaar:
            return [.regular: 1, .frugal: 1, .generous: 2, .urgent: 1, .tourist: 2, .vip: 4]
        }
    }

    // MARK: - Generate Customer

    static func generateCustomer(for locationType: ShopLocationType) -> Customer {
        // 1. Tipe göre profil seç
        let weights    = typeWeights(for: locationType)
        let pickedType = weightedRandomType(weights)

        // 2. Eşleşen profili seç
        let matching = allProfiles.filter { $0.customerType == pickedType }
        let profile  = matching.randomElement() ?? allProfiles[0]

        // 3. Yön ve slot sayısı
        let dir   = pickDirection(for: pickedType)
        let slots = Double.random(in: 0...1) < 0.65 ? 1 : 2

        // 4. Ürün kategorisi
        let pool = dir == .customerBuysFromPlayer
            ? preferredBuyCategories(for: pickedType)
            : preferredSellCategories(for: pickedType)
        let cat1 = pool.randomElement() ?? .goldGram
        let cat2: ProductCategory = {
            let others = pool.filter { $0 != cat1 }
            return others.randomElement() ?? .goldHalf
        }()

        // 5. Miktarlar
        let range = quantityRange(for: locationType)
        let qty1  = Int.random(in: range)
        let qty2  = Int.random(in: range)

        // 6. İstek öğeleri
        let item1 = RequestItem(productCategory: cat1, quantity: Double(qty1), label: requestLabel(qty: qty1, cat: cat1))
        let items: [RequestItem] = slots == 2
            ? [item1, RequestItem(productCategory: cat2, quantity: Double(qty2), label: requestLabel(qty: qty2, cat: cat2))]
            : [item1]

        // 7. Diyalog şablonu doldur
        let pool2: [String] = dir == .customerBuysFromPlayer
            ? (slots == 2 ? buyTemplates2  : buyTemplates1)
            : (slots == 2 ? sellTemplates2 : sellTemplates1)
        var dialogue = pool2.randomElement() ?? "{A} {B} istiyorum."
        dialogue = dialogue
            .replacingOccurrences(of: "{A}", with: "\(qty1)")
            .replacingOccurrences(of: "{B}", with: displayLabel(for: cat1))
            .replacingOccurrences(of: "{C}", with: "\(qty2)")
            .replacingOccurrences(of: "{D}", with: displayLabel(for: cat2))

        return Customer(
            id: UUID(),
            name: profile.name,
            age: profile.age,
            trait: profile.trait,
            generosity: generosity(for: pickedType),
            negotiationSkill: negotiationSkill(for: pickedType),
            patienceSeconds: patience(for: pickedType),
            customerType: pickedType,
            dialogue: dialogue,
            photoKey: profile.photoKey,
            request: CustomerRequest(id: UUID(), direction: dir, items: items)
        )
    }

    // MARK: - Weighted Random

    private static func weightedRandomType(_ weights: [CustomerType: Double]) -> CustomerType {
        let total = weights.values.reduce(0, +)
        guard total > 0 else { return .regular }
        var r = Double.random(in: 0..<total)
        for (type, weight) in weights {
            r -= weight
            if r <= 0 { return type }
        }
        return .regular
    }
}
