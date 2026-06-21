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

    // MARK: - Quantity by Category & Location

    private static func quantity(for cat: ProductCategory, loc: ShopLocationType) -> Int {
        switch cat {

        case .currencyUSD, .currencyEUR:
            // 100 ile 50.000 arası, 100'ün katları
            let maxSteps: Int
            switch loc {
            case .neighborhood:   maxSteps = 50    // 5.000
            case .bazaar:         maxSteps = 100   // 10.000
            case .districtBazaar: maxSteps = 150   // 15.000
            case .cityCenter:     maxSteps = 250   // 25.000
            case .mall:           maxSteps = 300   // 30.000
            case .grandBazaar:    maxSteps = 500   // 50.000
            }
            return Int.random(in: 1...maxSteps) * 100

        case .goldGram, .jewelry:
            // 10gr ile 100gr arası, 5'in katları
            let maxSteps: Int
            switch loc {
            case .neighborhood:   maxSteps = 4    // 20gr
            case .bazaar:         maxSteps = 6    // 30gr
            case .districtBazaar: maxSteps = 10   // 50gr
            case .cityCenter:     maxSteps = 15   // 75gr
            case .mall:           maxSteps = 15   // 75gr
            case .grandBazaar:    maxSteps = 20   // 100gr
            }
            return Int.random(in: 2...maxSteps) * 5

        case .goldQuarter, .goldHalf:
            // 5 ile 100 arası, 5'in katları
            let maxSteps: Int
            switch loc {
            case .neighborhood:   maxSteps = 4    // 20
            case .bazaar:         maxSteps = 6    // 30
            case .districtBazaar: maxSteps = 10   // 50
            case .cityCenter:     maxSteps = 15   // 75
            case .mall:           maxSteps = 15   // 75
            case .grandBazaar:    maxSteps = 20   // 100
            }
            return Int.random(in: 1...maxSteps) * 5

        case .goldFull:
            // 1 ile 50 arası, 1'in katları
            switch loc {
            case .neighborhood:   return Int.random(in: 1...5)
            case .bazaar:         return Int.random(in: 1...10)
            case .districtBazaar: return Int.random(in: 1...15)
            case .cityCenter:     return Int.random(in: 2...25)
            case .mall:           return Int.random(in: 2...25)
            case .grandBazaar:    return Int.random(in: 5...50)
            }
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

    // MARK: - Dialogue Templates (tipe göre, 25 şablon her tip: 15 tek + 10 çift)
    // {A}=miktar1, {B}=ürün1, {C}=miktar2, {D}=ürün2

    private static let dialogues: [CustomerType: (singleBuy: [String], singleSell: [String], dualBuy: [String], dualSell: [String])] = [

        // NORMAL — kibar, standart, tam cümleler
        // singleBuy  = müşteri bizden ALACAK (biz satıyoruz)
        // singleSell = müşteri bize SATACAK (biz alıyoruz)
        .regular: (
            singleBuy: [
                "Merhaba. {A} adet {B} almak istiyorum, fiyatınız nedir?",
                "Günaydın. {A} {B} almak istiyorum, müsait misiniz?",
                "Kolay gelsin. {A} {B} var mı elinizde, almak istiyorum.",
                "Merhaba. Yatırım için {A} adet {B} almak istiyorum.",
                "Kolay gelsin. {A} {B} almayı düşünüyorum, fiyat müsait mi?",
                "Selamünaleyküm. {A} adet {B} almak için geldim, fiyatınız nedir?",
                "Merhaba. Çeyizim için {A} {B} satın almak istiyorum.",
                "Günaydın. {A} {B} satın almak istiyorum, ne kadar eder?",
            ],
            singleSell: [
                "Selamünaleyküm usta. {A} adet {B} satmak istiyorum, ne verirsiniz?",
                "Kolay gelsin. Elimde {A} {B} var, satmak istiyorum.",
                "Selamlar usta. {A} {B} bozduruyorum, ne verirsiniz?",
                "Günaydın. {A} adet {B} satacağım, ne kadar alırsınız?",
                "Merhaba. Elimde {A} {B} var, ne kadar alırsınız?",
                "Kolay gelsin. {A} {B} satacağım, bugün fiyatınız ne?",
                "Selamünaleyküm. {A} {B} satmak istiyorum, adil fiyat verir misiniz?",
            ],
            dualBuy: [
                "Merhaba. {A} {B} ve {C} {D} almak istiyorum, fiyat ne olur?",
                "Kolay gelsin. {A} {B} ile {C} {D} almak istiyorum.",
                "Selamünaleyküm. Hem {A} {B} hem de {C} {D} almak istiyorum.",
                "Merhaba. {A} {B} ve {C} {D} istiyorum, en iyi fiyat nedir?",
                "Merhaba. {A} {B} ve {C} {D} almak için geldim.",
            ],
            dualSell: [
                "Merhaba. Elimde {A} {B} ve {C} {D} var, satabilir miyim?",
                "Günaydın. {A} {B} ve {C} {D} bozduruyorum, ne verirsiniz?",
                "Kolay gelsin. {A} {B} ile {C} {D} satacağım, teklifiniz nedir?",
                "Selamünaleyküm. {A} {B} ve {C} {D} satmak istiyorum, fiyat nedir?",
                "Merhaba. {A} {B} ile {C} {D} var elimde, alır mısınız?",
            ]
        ),

        // TUTUMLU — fiyat odaklı, indirim arayan
        .frugal: (
            singleBuy: [
                "Hayırlı işler. {A} {B} almak istiyorum, en uygun fiyatınız nedir?",
                "Günaydın. {A} {B} almak istiyorum, önce fiyatı öğreneyim.",
                "Hayırlı işler. {A} {B} almak istiyorum, fiyatta anlaşabilir miyiz?",
                "Merhaba. {A} adet {B} için makul bir fiyat olur mu?",
                "Günaydın. Fiyatı uygunsa {A} {B} alacağım, ne dersiniz?",
                "Hayırlı işler. {A} {B} için biraz daha iyi fiyat verebilir misiniz?",
                "Merhaba. {A} {B} almak istiyorum, son satış fiyatınız nedir?",
            ],
            singleSell: [
                "Günaydın. {A} {B} satacağım, en iyi fiyatı siz verin.",
                "Hayırlı işler. {A} {B} bozduruyorum, kaç para verirsiniz?",
                "Merhaba. {A} {B} satmak istiyorum, en iyi teklifiniz nedir?",
                "Günaydın. Elimde {A} {B} var, ne kadar alırsınız?",
                "Hayırlı işler. {A} {B} satacağım, fiyat verin bir bakayım.",
                "Merhaba. {A} {B} satmak istiyorum, iyi fiyat verir misiniz?",
            ],
            dualBuy: [
                "Hayırlı işler. {A} {B} ve {C} {D} alacağım, indirim yapar mısınız?",
                "Günaydın. {A} {B} ve {C} {D} almak istiyorum, paket fiyat olur mu?",
                "Hayırlı işler. {A} {B} ile {C} {D} alacağım, toptan indirim olur mu?",
                "Merhaba. {A} {B} ve {C} {D} almak istiyorum, bütçem kısıtlı.",
                "Günaydın. {A} {B} ile {C} {D} alırsam indirim yapar mısınız?",
            ],
            dualSell: [
                "Hayırlı işler. {A} {B} ve {C} {D} satacağım, ne verirsiniz?",
                "Günaydın. {A} {B} ve {C} {D} bozduruyorum, toplam ne kadar eder?",
                "Merhaba. Elimde {A} {B} ve {C} {D} var, uygun teklif nedir?",
                "Hayırlı işler. {A} {B} ile {C} {D} satmak istiyorum, fiyat verin.",
                "Günaydın. {A} {B} ve {C} {D} satacağım, iyi alırsanız getiririm.",
            ]
        ),

        // CÖMERT — sıcak, etkinlik odaklı, fiyata duyarsız
        .generous: (
            singleBuy: [
                "Selamlar. {A} {B} almak istiyorum, en güzeli olsun.",
                "Merhaba. Düğün hediyesi için {A} {B} almak istiyorum.",
                "Günaydın. Kızıma sürpriz için {A} {B} alabilir miyim?",
                "Selamlar. Annem için {A} {B} alacağım, hayırlısı olsun.",
                "Merhaba. Nişan hediyesi için {A} {B} alacağım.",
                "Günaydın. Torunum için {A} {B} alacağım, hayırlı olsun.",
                "Selamlar. Bayrama özel {A} {B} almak istiyorum.",
                "Merhaba. {A} {B} almak istiyorum, kaliteli olsun yeter.",
            ],
            singleSell: [
                "Merhaba. Elimde {A} {B} var, satmak istiyorum.",
                "Günaydın. {A} {B} bozduruyorum, adil fiyat verin.",
                "Selamlar. {A} {B} satmak istiyorum, değerince alın.",
                "Merhaba. {A} {B} satacağım, iyi fiyat verir misiniz?",
                "Günaydın. Elimde {A} {B} var, hayırlı satış olsun.",
            ],
            dualBuy: [
                "Selamlar. {A} {B} ile {C} {D} almak istiyorum, güzel seçin.",
                "Merhaba. Çeyiz için {A} {B} ve {C} {D} almak istiyorum.",
                "Günaydın. Hem {A} {B} hem {C} {D} alacağım, iyi seçin.",
                "Selamlar. {A} {B} ve {C} {D} istiyorum, fiyatı sizin bildiğiniz.",
                "Merhaba. Düğün takısı için {A} {B} ve {C} {D} lazım.",
            ],
            dualSell: [
                "Selamlar. {A} {B} ile {C} {D} satacağım, değerince alın.",
                "Merhaba. Elimde {A} {B} ve {C} {D} var, satmak istiyorum.",
                "Günaydın. {A} {B} ve {C} {D} bozduruyorum, adil fiyat verin.",
                "Selamlar. {A} {B} ve {C} {D} satmak istiyorum, hayırlısı olsun.",
                "Merhaba. {A} {B} ile {C} {D} var elimde, alır mısınız?",
            ]
        ),

        // ACİL — kısa, doğrudan, sabırsız
        .urgent: (
            singleBuy: [
                "Merhaba. {A} {B} almak istiyorum, ne kadar?",
                "Acele var. {A} {B} satıyor musunuz, kaç para?",
                "Hızlı olalım. {A} {B} almak istiyorum.",
                "{A} tane {B} alacağım, kaç lira?",
                "Çabuk olsun. {A} {B} alacağım, fiyat ne?",
                "Vakit yok. {A} {B} var mı elinizde, alıyorum.",
                "Hemen {A} {B} almak istiyorum, fiyat söyleyin.",
            ],
            singleSell: [
                "Acelem var. {A} {B} satacağım, kaç verirsiniz?",
                "{A} {B} bozduruyorum, hemen halledelim.",
                "Hızlı olalım. {A} {B} satmak istiyorum.",
                "{A} {B} satacağım, kaç para, çabuk söyleyin.",
                "Acelem var, {A} {B} satacağım, teklif verin.",
                "Hızlı olsun. Elimde {A} {B} var, alır mısınız?",
            ],
            dualBuy: [
                "{A} {B} ve {C} {D} alacağım, toplam ne kadar?",
                "Hızlı olsun. {A} {B} ile {C} {D} almak istiyorum.",
                "Acelem var. {A} {B} ile {C} {D} alacağım, ne kadar?",
                "Çabuk bakar mısınız, {A} {B} ve {C} {D} alacağım.",
                "{A} {B} ile {C} {D} istiyorum, hızlıca halledelim.",
            ],
            dualSell: [
                "{A} {B} ve {C} {D} satacağım, toplam ne verirsiniz?",
                "Hızlı olalım. {A} {B} ve {C} {D} bozduruyorum.",
                "Acele var. {A} {B} ile {C} {D} satacağım, fiyat?",
                "{A} {B} ve {C} {D} satacağım, hızlıca söyleyin.",
                "Çabuk bakar mısınız, {A} {B} ve {C} {D} satacağım.",
            ]
        ),

        // TURİST — sade Türkçe, meraklı, arkadaşça
        .tourist: (
            singleBuy: [
                "İyi günler. {A} tane {B} alabilir miyim, ne kadar?",
                "Merhaba. {A} {B} ne kadar lira?",
                "Selam. {A} adet {B} almak istiyorum. Mümkün mü?",
                "İyi günler. {A} tane {B} almak istiyorum.",
                "Selam. {A} tane {B} satabilir misiniz bana?",
                "İyi günler. Ben {A} {B} almak istiyorum, tamam mı?",
                "Merhaba. {A} adet {B} istiyorum, kaç para?",
                "Selam. {A} {B} alıyorum, ne kadar öderim?",
            ],
            singleSell: [
                "İyi günler. {A} tane {B} satmak istiyorum. Alır mısınız?",
                "Merhaba. Elimde {A} {B} var, ne kadar verirsiniz?",
                "Selam. {A} {B} bozdurabilir miyim burada?",
                "İyi günler. {A} {B} satıyorum, ne kadar alırsınız?",
                "Merhaba. {A} adet {B} satmak istiyorum, kaç para?",
            ],
            dualBuy: [
                "İyi günler. {A} {B} ve {C} {D} almak istiyorum, kaç lira?",
                "Merhaba. {A} {B} ile {C} {D}, toplam ne kadar?",
                "Selam. {A} tane {B} ve {C} tane {D} almak istiyorum.",
                "İyi günler. {A} {B} ve {C} {D} alabilir miyim?",
                "Selam. {A} {B} ile {C} {D} almak mümkün mü?",
            ],
            dualSell: [
                "İyi günler. {A} {B} ve {C} {D} satmak istiyorum. Alır mısınız?",
                "Merhaba. Elimde {A} {B} ve {C} {D} var, ne verirsiniz?",
                "Selam. {A} {B} ile {C} {D} bozdurabilir miyim?",
                "İyi günler. {A} {B} ve {C} {D} satıyorum, ne kadar alırsınız?",
                "Merhaba. {A} tane {B} ve {C} tane {D} satmak istiyorum.",
            ]
        ),

        // VIP — buyurgan, kendinden emin, en iyisini bekliyor
        .vip: (
            singleBuy: [
                "Selam. {A} tane {B} istiyorum, en iyisinden olsun.",
                "Merhaba. {A} {B} al bana, hemen halledelim.",
                "Selam. {A} adet {B} istiyorum, kalitesinden emin ol.",
                "Merhaba. {A} {B} var mı, iyi ise alıyorum.",
                "Selam. {A} {B} lazım, ayarlayabilir misin?",
                "Merhaba. {A} {B} alacağım, en kalitelisi olsun.",
                "Selam. {A} adet {B} istiyorum, hızlı halledelim.",
                "Merhaba. {A} tane {B} almak istiyorum, kaliteli olsun.",
            ],
            singleSell: [
                "Selam. {A} {B} satmak istiyorum, iyi fiyat ver.",
                "Merhaba. {A} {B} bozduruyorum, ne veriyorsun?",
                "Selam. {A} {B} satacağım, teklifini söyle.",
                "Merhaba. Elimde {A} {B} var, alırsın mı?",
                "Selam. {A} adet {B} satacağım, en iyi fiyatı ver.",
            ],
            dualBuy: [
                "Selam. {A} {B} ile {C} {D} istiyorum, ikisini de ayarla.",
                "Merhaba. {A} {B} ve {C} {D} al bana, en iyisi.",
                "Selam. {A} {B} ile {C} {D} istiyorum, hızlı olsun.",
                "Merhaba. {A} {B} ve {C} {D} ayarlar mısın benim için?",
                "Selam. Hem {A} {B} hem {C} {D} lazım, halleder misin?",
            ],
            dualSell: [
                "Merhaba. {A} {B} ile {C} {D} satacağım, iyi fiyat ver.",
                "Selam. {A} {B} ve {C} {D} için teklifini söyle.",
                "Merhaba. Elimde {A} {B} ve {C} {D} var, alır mısın?",
                "Selam. {A} {B} ile {C} {D} bozduruyorum, ne veriyorsun?",
                "Merhaba. {A} {B} ve {C} {D} satacağım, iyi fiyat ver.",
            ]
        ),
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

    private static func typeWeights(
        for loc: ShopLocationType,
        vipModifier: Double = 1.0
    ) -> [CustomerType: Double] {
        var weights: [CustomerType: Double]
        switch loc {
        case .neighborhood:
            weights = [.regular: 4, .frugal: 3, .generous: 1, .urgent: 2, .tourist: 0, .vip: 0]
        case .bazaar:
            weights = [.regular: 3, .frugal: 2, .generous: 2, .urgent: 2, .tourist: 1, .vip: 0]
        case .districtBazaar:
            weights = [.regular: 3, .frugal: 2, .generous: 2, .urgent: 2, .tourist: 1, .vip: 1]
        case .cityCenter:
            weights = [.regular: 2, .frugal: 1, .generous: 2, .urgent: 2, .tourist: 2, .vip: 1]
        case .mall:
            weights = [.regular: 2, .frugal: 1, .generous: 2, .urgent: 1, .tourist: 3, .vip: 2]
        case .grandBazaar:
            weights = [.regular: 1, .frugal: 1, .generous: 2, .urgent: 1, .tourist: 2, .vip: 4]
        }

        let clampedVIPModifier = max(0.5, min(vipModifier, 2.5))
        if let vipWeight = weights[.vip], vipWeight > 0 {
            weights[.vip] = vipWeight * clampedVIPModifier
        }

        return weights
    }

    // MARK: - Generate Customer

    static func generateCustomer(
        for locationType: ShopLocationType,
        vipModifier: Double = 1.0
    ) -> Customer {
        // 1. Tipe göre profil seç
        let weights    = typeWeights(for: locationType, vipModifier: vipModifier)
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

        // 5. Miktarlar (kategoriye ve lokasyona göre)
        let qty1 = quantity(for: cat1, loc: locationType)
        let qty2 = quantity(for: cat2, loc: locationType)

        // 6. İstek öğeleri
        let item1 = RequestItem(productCategory: cat1, quantity: Double(qty1), label: requestLabel(qty: qty1, cat: cat1))
        let items: [RequestItem] = slots == 2
            ? [item1, RequestItem(productCategory: cat2, quantity: Double(qty2), label: requestLabel(qty: qty2, cat: cat2))]
            : [item1]

        // 7. Diyalog şablonu doldur (tipe ve yöne göre)
        let typeDials = Self.dialogues[pickedType] ?? Self.dialogues[.regular]!
        let pool2: [String]
        if slots == 2 {
            pool2 = dir == .customerBuysFromPlayer ? typeDials.dualBuy : typeDials.dualSell
        } else {
            pool2 = dir == .customerBuysFromPlayer ? typeDials.singleBuy : typeDials.singleSell
        }
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
