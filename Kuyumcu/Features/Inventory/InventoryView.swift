import SwiftUI

// MARK: - Trade Sheet Config

struct TradeSheetConfig: Identifiable {
    let id = UUID()
    let category: ProductCategory
    let name: String
    let unit: String
    let isBuying: Bool
}

// MARK: - InventoryView

struct InventoryView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    @State private var tradeConfig: TradeSheetConfig? = nil
    @State private var selectedTrendProduct: InventoryTrendProduct = .usd
    @State private var rateHistoryRows: [GoldRateHistoryRow] = []
    @State private var isRateHistoryLoading = false

    private var inv: Inventory { gameState.inventory }

    private func buyRate(_ key: String) -> Double { gameState.rate(for: key)?.buyPrice  ?? 0 }
    private func selRate(_ key: String) -> Double { gameState.rate(for: key)?.sellPrice ?? 0 }

    private var totalInventoryValue: Double {
        inv.gramGold    * buyRate("gramGold")    +
        inv.quarterGold * buyRate("quarterGold") +
        inv.halfGold    * buyRate("halfGold")    +
        inv.fullGold    * buyRate("fullGold")    +
        inv.usd         * buyRate("USD")         +
        inv.eur         * buyRate("EUR")
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: GDLSpacing.md) {
                    summaryCard
                    tlCashCard
                    priceTrendCard
                    inventoryListCard
                    Spacer(minLength: 80)
                }
                .padding(.top, GDLSpacing.md)
            }

            // Merkezi al/sat diyaloğu
            if let cfg = tradeConfig {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { tradeConfig = nil }

                QuickTradeDialog(config: cfg, onDismiss: { tradeConfig = nil })
                    .environmentObject(gameState)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: tradeConfig != nil)
                    .padding(.horizontal, GDLSpacing.xxl)
            }
        }
        .gdlScreenBackground()
        .navigationTitle("Envanter")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRateHistory()
        }
    }

    // MARK: - Summary + TL Cash Row

    private var summaryCard: some View {
        HStack(spacing: GDLSpacing.md) {
            // Sol: Toplam değer
            VStack(alignment: .leading, spacing: GDLSpacing.xs) {
                HStack(spacing: GDLSpacing.xs) {
                    Image(systemName: "archivebox.fill").font(.caption).foregroundColor(.gdlGold)
                    Text("Toplam Değer").font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                }
                Text(FormatUtils.tl(gameState.playerCash + totalInventoryValue))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.gdlGold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("TL Nakit + Envanter")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GDLSpacing.md)
            .gdlCard()

            // Sağ: TL Nakit
            VStack(alignment: .leading, spacing: GDLSpacing.xs) {
                HStack(spacing: GDLSpacing.xs) {
                    Image(systemName: "turkishlirasign.circle.fill").font(.caption).foregroundColor(.gdlGold)
                    Text("TL Nakit").font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                }
                Text(FormatUtils.tl(gameState.playerCash))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.gdlTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: GDLSpacing.xxs) {
                    Image(systemName: "clock").font(.system(size: 10)).foregroundColor(.gdlTextSecondary)
                    Text(gameState.yesterdayCash > 0
                         ? "Dün: \(FormatUtils.tl(gameState.yesterdayCash))"
                         : "Geçmiş veri yok")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GDLSpacing.md)
            .gdlCard()
        }
        .padding(.horizontal)
    }

    private var tlCashCard: some View { EmptyView() }

    private var trendPoints: [InventoryTrendPoint] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let mapped = rateHistoryRows.compactMap { row -> InventoryTrendPoint? in
            guard let date = formatter.date(from: row.snapshotDate) else { return nil }
            return InventoryTrendPoint(date: date, value: selectedTrendProduct.value(from: row))
        }
        .sorted { $0.date < $1.date }

        if !mapped.isEmpty {
            return mapped
        }

        let fallback = selectedTrendProduct.currentBuyPrice(from: gameState)
        guard fallback > 0 else { return [] }
        return [InventoryTrendPoint(date: Date(), value: fallback)]
    }

    private var priceTrendCard: some View {
        VStack(alignment: .leading, spacing: GDLSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GDLSpacing.xs) {
                    ForEach(InventoryTrendProduct.allCases) { product in
                        Button {
                            selectedTrendProduct = product
                        } label: {
                            Text(product.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTrendProduct == product ? .black : .gdlTextPrimary)
                                .padding(.horizontal, GDLSpacing.sm)
                                .padding(.vertical, 7)
                                .background(selectedTrendProduct == product ? product.color : Color.gdlCardSecondary)
                                .cornerRadius(999)
                        }
                    }
                }
            }

            if isRateHistoryLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.gdlGold)
            }

            if trendPoints.isEmpty {
                Text("Grafik verisi hazırlanıyor.")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
            } else {
                InventoryTrendLineChart(points: trendPoints, lineColor: selectedTrendProduct.color)
                    .frame(height: 128)

                HStack {
                    Text(trendPoints.first.map { InventoryTrendPoint.labelFormatter.string(from: $0.date) } ?? "-")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary)
                    Spacer()
                    Text(trendPoints.last.map { InventoryTrendPoint.labelFormatter.string(from: $0.date) } ?? "-")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary)
                }
            }
        }
        .padding(.horizontal, GDLSpacing.md)
        .padding(.vertical, GDLSpacing.sm)
        .gdlCard()
        .padding(.horizontal)
    }

    private func loadRateHistory() async {
        await MainActor.run { isRateHistoryLoading = true }
        let rows = await SupabaseSaveService.fetchRateHistory(days: 30)
        await MainActor.run {
            rateHistoryRows = rows
            isRateHistoryLoading = false
        }
    }

    // MARK: - Inventory List Card

    private var inventoryListCard: some View {
        SectionCard(title: "Varlıklar", icon: "list.bullet") {
            VStack(spacing: 0) {
                tradeRow(label: "Dolar",        icon: "dollarsign.circle.fill",
                         color: Color(red: 0.2, green: 0.78, blue: 0.35),
                         amount: FormatUtils.wholeNumber(inv.usd) + " USD",
                         value: FormatUtils.tl(inv.usd * buyRate("USD")),
                         category: .currencyUSD, unit: "USD")
                rowDivider
                tradeRow(label: "Euro",         icon: "eurosign.circle.fill",
                         color: Color(red: 0.25, green: 0.55, blue: 1.0),
                         amount: FormatUtils.wholeNumber(inv.eur) + " EUR",
                         value: FormatUtils.tl(inv.eur * buyRate("EUR")),
                         category: .currencyEUR, unit: "EUR")
                rowDivider
                tradeRow(label: "Gram Altın",   icon: "circle.fill", color: .gdlGold,
                         amount: FormatUtils.wholeNumber(inv.gramGold) + " gr",
                         value: FormatUtils.tl(inv.gramGold * buyRate("gramGold")),
                         category: .goldGram, unit: "gr")
                rowDivider
                tradeRow(label: "Çeyrek Altın", icon: "circle.lefthalf.filled", color: .gdlGoldLight,
                         amount: FormatUtils.wholeNumber(inv.quarterGold) + " adet",
                         value: FormatUtils.tl(inv.quarterGold * buyRate("quarterGold")),
                         category: .goldQuarter, unit: "adet")
                rowDivider
                tradeRow(label: "Yarım Altın",  icon: "circle.bottomhalf.filled", color: .gdlGoldLight,
                         amount: FormatUtils.wholeNumber(inv.halfGold) + " adet",
                         value: FormatUtils.tl(inv.halfGold * buyRate("halfGold")),
                         category: .goldHalf, unit: "adet")
                rowDivider
                tradeRow(label: "Tam Altın",    icon: "seal.fill", color: .gdlGold,
                         amount: FormatUtils.wholeNumber(inv.fullGold) + " adet",
                         value: FormatUtils.tl(inv.fullGold * buyRate("fullGold")),
                         category: .goldFull, unit: "adet")
            }
        }
        .padding(.horizontal)
    }

    private var rowDivider: some View {
        Divider().background(Color.gdlDivider).padding(.vertical, GDLSpacing.xxxs)
    }

    private func tradeRow(label: String, icon: String, color: Color,
                          amount: String, value: String,
                          category: ProductCategory, unit: String) -> some View {
        HStack(spacing: GDLSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: GDLSpacing.xxxs) {
                Text(label)
                    .font(.gdlBody()).foregroundColor(.gdlTextPrimary)
                Text(amount)
                    .font(.gdlCaption()).foregroundColor(.gdlGold)
            }

            Spacer()

            Text(value)
                .font(.system(size: 11))
                .foregroundColor(.gdlTextSecondary)
                .lineLimit(1)

            HStack(spacing: GDLSpacing.xs) {
                tradeButton("Sat", isBuy: false) {
                    audioManager.playEffect(.buttonTap)
                    tradeConfig = TradeSheetConfig(category: category, name: label, unit: unit, isBuying: false)
                }
                tradeButton("Al", isBuy: true) {
                    audioManager.playEffect(.buttonTap)
                    tradeConfig = TradeSheetConfig(category: category, name: label, unit: unit, isBuying: true)
                }
            }
        }
        .padding(.vertical, GDLSpacing.sm)
    }

    private func tradeButton(_ title: String, isBuy: Bool, action: @escaping () -> Void) -> some View {
        CompactActionButton(
            title: title,
            style: isBuy ? .positive : .negative,
            minWidth: 48,
            action: action
        )
    }
}

private enum InventoryTrendProduct: String, CaseIterable, Identifiable {
    case usd
    case eur
    case gramGold
    case quarterGold
    case halfGold
    case fullGold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .usd: return "Dolar"
        case .eur: return "Euro"
        case .gramGold: return "Gram Altın"
        case .quarterGold: return "Çeyrek Altın"
        case .halfGold: return "Yarım Altın"
        case .fullGold: return "Tam Altın"
        }
    }

    var color: Color {
        switch self {
        case .usd: return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .eur: return Color(red: 0.25, green: 0.55, blue: 1.0)
        case .gramGold, .quarterGold, .halfGold, .fullGold: return .gdlGold
        }
    }

    func value(from row: GoldRateHistoryRow) -> Double {
        switch self {
        case .usd: return row.usdBuy
        case .eur: return row.eurBuy
        case .gramGold: return row.gramBuy
        case .quarterGold: return row.quarterBuy
        case .halfGold: return row.halfBuy
        case .fullGold: return row.fullBuy
        }
    }

    func currentBuyPrice(from gameState: GameState) -> Double {
        let rateKey: String
        switch self {
        case .usd: rateKey = "USD"
        case .eur: rateKey = "EUR"
        case .gramGold: rateKey = "gramGold"
        case .quarterGold: rateKey = "quarterGold"
        case .halfGold: rateKey = "halfGold"
        case .fullGold: rateKey = "fullGold"
        }
        return gameState.rate(for: rateKey)?.buyPrice ?? 0
    }
}

private struct InventoryTrendPoint: Identifiable {
    let date: Date
    let value: Double
    var id: String { "\(date.timeIntervalSince1970)-\(value)" }

    static let labelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM"
        return formatter
    }()
}

private struct InventoryTrendLineChart: View {
    let points: [InventoryTrendPoint]
    let lineColor: Color

    var body: some View {
        GeometryReader { geometry in
            let values = points.map(\.value)
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 0
            let valueRange = max(maxValue - minValue, 1)
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gdlCardSecondary.opacity(0.6))

                Path { path in
                    for (index, point) in points.enumerated() {
                        let x: CGFloat
                        if points.count == 1 {
                            x = width / 2
                        } else {
                            x = CGFloat(index) / CGFloat(points.count - 1) * width
                        }
                        let normalized = (point.value - minValue) / valueRange
                        let y = height - CGFloat(normalized) * height
                        let position = CGPoint(x: x, y: y)
                        if index == 0 {
                            path.move(to: position)
                        } else {
                            path.addLine(to: position)
                        }
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

                HStack {
                    Text(FormatUtils.tl(maxValue))
                        .font(.system(size: 10))
                        .foregroundColor(.gdlTextSecondary)
                    Spacer()
                    Text(FormatUtils.tl(minValue))
                        .font(.system(size: 10))
                        .foregroundColor(.gdlTextSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }
        }
    }
}

// MARK: - Quick Trade Dialog (merkezi overlay)

struct QuickTradeDialog: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    let config: TradeSheetConfig
    let onDismiss: () -> Void

    @State private var qtyText: String = ""

    private var inv: Inventory { gameState.inventory }

    private var rateKey: String {
        switch config.category {
        case .goldGram:    return "gramGold"
        case .goldQuarter: return "quarterGold"
        case .goldHalf:    return "halfGold"
        case .goldFull:    return "fullGold"
        case .currencyUSD: return "USD"
        case .currencyEUR: return "EUR"
        case .jewelry:     return "gramGold"
        }
    }

    private var unitPrice: Double {
        let r = gameState.rate(for: rateKey)
        return config.isBuying ? (r?.sellPrice ?? 0) : (r?.buyPrice ?? 0)
    }

    private var qty: Double { Double(qtyText) ?? 0 }
    private var totalTL: Double { qty * unitPrice }

    private var availableStock: Double {
        switch config.category {
        case .goldGram:    return inv.gramGold
        case .goldQuarter: return inv.quarterGold
        case .goldHalf:    return inv.halfGold
        case .goldFull:    return inv.fullGold
        case .currencyUSD: return inv.usd
        case .currencyEUR: return inv.eur
        case .jewelry:     return inv.gramGold
        }
    }

    private var canTrade: Bool {
        guard qty > 0 else { return false }
        return config.isBuying ? gameState.playerCash >= totalTL : availableStock >= qty
    }

    var body: some View {
        VStack(spacing: 0) {

            // Başlık
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.isBuying ? "Satın Al" : "Sat")
                        .font(.gdlHeadline())
                        .foregroundColor(config.isBuying ? .gdlGold : .gdlNegative)
                    Text(config.name)
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }
                Spacer()
                Button {
                    audioManager.playEffect(.buttonTap)
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gdlTextSecondary)
                        .padding(7)
                        .background(Color.gdlCardSecondary)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().background(Color.gdlDivider)

            // Fiyat + bakiye/stok
            VStack(spacing: 8) {
                infoRow(
                    label: config.isBuying ? "Birim Alış" : "Birim Satış",
                    value: "\(FormatUtils.tl(unitPrice)) / \(config.unit)"
                )
                infoRow(
                    label: config.isBuying ? "Nakit" : "Stok",
                    value: config.isBuying
                        ? FormatUtils.tl(gameState.playerCash)
                        : "\(FormatUtils.decimal(availableStock)) \(config.unit)"
                )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider().background(Color.gdlDivider)

            // Miktar girişi
            HStack {
                Text("Miktar (\(config.unit))")
                    .font(.gdlBody())
                    .foregroundColor(.gdlTextSecondary)
                Spacer()
                TextField("0", text: $qtyText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.gdlTextPrimary)
                    .frame(width: 110)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            // Hızlı miktar
            HStack(spacing: 6) {
                ForEach([1, 5, 10, 50, 100, 1000], id: \.self) { n in
                    Button {
                        audioManager.playEffect(.buttonTap)
                        qtyText = "\(n)"
                    } label: {
                        Text("\(n)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gdlTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.gdlCardSecondary)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 18)

            Divider().background(Color.gdlDivider).padding(.top, 14)

            // Toplam + onay
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Toplam")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                    Text(FormatUtils.tl(totalTL))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(config.isBuying ? .gdlGold : .gdlPositive)
                }
                Spacer()
                CompactActionButton(
                    title: config.isBuying ? "Satın Al" : "Sat",
                    style: config.isBuying ? .gold : .negative,
                    isDisabled: !canTrade
                ) {
                    guard canTrade else { return }
                    audioManager.playEffect(.purchase)
                    gameState.quickTrade(category: config.category, qty: qty, isBuying: config.isBuying)
                    onDismiss()
                }
                .disabled(!canTrade)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(LinearGradient.gdlOuterSurface)
        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.shellOuterRadius))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
            Spacer()
            Text(value).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        InventoryView()
            .environmentObject(GameState())
            .environmentObject(AudioManager.shared)
    }
}
