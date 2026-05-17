import Foundation

// MARK: - Fetch Result

struct FetchedRates {
    let gramGoldTRY:    Double  // GA alis
    let gramGoldSell:   Double  // GA satis
    let quarterGoldTRY: Double  // C alis
    let quarterGoldSell:Double  // C satis
    let halfGoldTRY:    Double  // Y alis
    let halfGoldSell:   Double  // Y satis
    let fullGoldTRY:    Double  // T alis
    let fullGoldSell:   Double  // T satis
    let usdTRY:         Double  // USD alis
    let usdSell:        Double  // USD satis
    let eurTRY:         Double  // EUR alis
    let eurSell:        Double  // EUR satis
    let dateString:     String
    let sourceName:     String
}

// MARK: - Service

class RateFetchService {

    static let shared = RateFetchService()
    private let lastFetchKey = "rateFetchDate_v3"

    // Türkiye saatiyle bugün 08:00'dan sonra çekildi mi?
    // TODO: Canlıya alınca aşağıdaki mantığı aç, geçici satırı kaldır.
    func shouldFetch() -> Bool {
        return true  // Geçici: her girişte çek (test modu)

        // --- Canlı mantık (test sonrası aktif et) ---
        // guard let last = UserDefaults.standard.object(forKey: lastFetchKey) as? Date else { return true }
        // var cal = Calendar(identifier: .gregorian)
        // cal.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        // if !cal.isDateInToday(last) { return true }
        // let lastHour = cal.component(.hour, from: last)
        // let nowHour  = cal.component(.hour, from: Date())
        // if nowHour >= 8 && lastHour < 8 { return true }
        // return false
    }

    func fetchRates() async throws -> FetchedRates {
        // Tek URL ile hem altın hem döviz çek (2 paralel istek)
        async let goldTask = fetchGold()
        async let fxTask   = fetchFX()

        let gold = try await goldTask
        let fx   = try await fxTask

        UserDefaults.standard.set(Date(), forKey: lastFetchKey)

        let fmt = DateFormatter()
        fmt.locale     = Locale(identifier: "tr_TR")
        fmt.dateFormat = "d MMMM yyyy"

        return FetchedRates(
            gramGoldTRY:     gold.gramAlis,
            gramGoldSell:    gold.gramSatis,
            quarterGoldTRY:  gold.ceyrekAlis,
            quarterGoldSell: gold.ceyrekSatis,
            halfGoldTRY:     gold.yarimAlis,
            halfGoldSell:    gold.yarimSatis,
            fullGoldTRY:     gold.tamAlis,
            fullGoldSell:    gold.tamSatis,
            usdTRY:          fx.usdAlis,
            usdSell:         fx.usdSatis,
            eurTRY:          fx.eurAlis,
            eurSell:         fx.eurSatis,
            dateString:      fmt.string(from: Date()),
            sourceName:      "genelpara.com"
        )
    }

    // MARK: - Private

    private struct GoldResult {
        let gramAlis, gramSatis: Double
        let ceyrekAlis, ceyrekSatis: Double
        let yarimAlis, yarimSatis: Double
        let tamAlis, tamSatis: Double
    }

    private struct FXResult {
        let usdAlis, usdSatis: Double
        let eurAlis, eurSatis: Double
    }

    // Yanıt yapısı: {"success":true,"data":{"GA":{"alis":"6610.00","satis":"6650.00",...},...}}
    private struct GPResponse: Decodable {
        let success: Bool
        let data: [String: GPItem]
    }

    private struct GPItem: Decodable {
        let alis: String
        let satis: String
    }

    private func fetchGold() async throws -> GoldResult {
        let url = URL(string: "https://api.genelpara.com/json/?list=altin&sembol=GA,C,Y,T")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let resp = try JSONDecoder().decode(GPResponse.self, from: data)

        func price(_ sym: String, isSatis: Bool) -> Double {
            let str = isSatis ? (resp.data[sym]?.satis ?? "0") : (resp.data[sym]?.alis ?? "0")
            return Double(str.replacingOccurrences(of: ",", with: ".")) ?? 0
        }

        return GoldResult(
            gramAlis:    price("GA", isSatis: false),
            gramSatis:   price("GA", isSatis: true),
            ceyrekAlis:  price("C",  isSatis: false),
            ceyrekSatis: price("C",  isSatis: true),
            yarimAlis:   price("Y",  isSatis: false),
            yarimSatis:  price("Y",  isSatis: true),
            tamAlis:     price("T",  isSatis: false),
            tamSatis:    price("T",  isSatis: true)
        )
    }

    private func fetchFX() async throws -> FXResult {
        let url = URL(string: "https://api.genelpara.com/json/?list=doviz&sembol=USD,EUR")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let resp = try JSONDecoder().decode(GPResponse.self, from: data)

        func price(_ sym: String, isSatis: Bool) -> Double {
            let str = isSatis ? (resp.data[sym]?.satis ?? "0") : (resp.data[sym]?.alis ?? "0")
            return Double(str.replacingOccurrences(of: ",", with: ".")) ?? 0
        }

        return FXResult(
            usdAlis:  price("USD", isSatis: false),
            usdSatis: price("USD", isSatis: true),
            eurAlis:  price("EUR", isSatis: false),
            eurSatis: price("EUR", isSatis: true)
        )
    }
}
