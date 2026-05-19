import SwiftUI
import Combine

// Module-level constant so the same publisher instance is reused across renders
private let counterTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

private let competitorNames = [
    "Kuyumcu Hüseyin", "Sarraf Mehmet",    "Altın Sarayı",
    "Asrın Kuyumculuk","Zirve Kuyumculuk", "Gran Bijuteri",
    "Refah Kuyumcu",   "Altın Dünya",      "Sümer Kuyumcusu",
    "Altın Çağ",       "Bereket Sarrafiye","Nizam Kuyumcu",
    "Halis Bijuteri",  "Zafer Altın",      "Yıldız Sarraf",
    "Cevher Kuyumcu",  "Hilal Altın",      "Özhan Sarrafiye",
    "Pırlanta Köşkü",  "Çınar Kuyumcu",
]

struct CounterView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) var dismiss

    // MARK: - Local State
    @State private var offerInput: String = ""
    @State private var timeRemaining: Double = 60
    @State private var showResult: Bool = false
    @State private var lastResult: TransactionResult = .rejected
    @State private var lastProfit: Double = 0
    @State private var isBargainPhase: Bool = false
    @State private var competitorOffers: [(name: String, price: Double)] = []
    @State private var showInsufficientCash: Bool = false
    @State private var showLossWarning: Bool = false
    @State private var pendingOfferValue: Double = 0
    @State private var toastOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if let customer = gameState.currentCustomer {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            sceneView(customer: customer)
                                .overlay(alignment: .bottom) {
                                    if showResult {
                                        resultToast
                                            .opacity(toastOpacity)
                                            .animation(.easeInOut(duration: 0.25), value: toastOpacity)
                                    }
                                }
                            Rectangle().fill(Color.gdlGold.opacity(0.35)).frame(height: 2)
                            competitorOffersSection(customer: customer)
                                .padding(.horizontal, 14)
                            Rectangle().fill(Color.gdlGold.opacity(0.35)).frame(height: 2)
                            keypadSection(customer: customer)
                                .padding(.horizontal, 14)
                        }
                        .padding(.bottom, 20)
                    }
                } else {
                    waitingForCustomerView
                }
            }

        // (toast sceneView overlay'inde gösterilir)
        }
        .onReceive(counterTimer) { _ in
            guard gameState.currentCustomer != nil, !showResult else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                handleTimerExpired()
            }
        }
        .onChange(of: gameState.currentCustomer?.id) { _, _ in
            resetForNewCustomer()
        }
        .onAppear {
            resetForNewCustomer()
            audioManager.enterCounterScreen()
        }
        .onDisappear {
            audioManager.exitCounterScreen()
        }
        .onChange(of: showResult) { _, isShowing in
            if isShowing {
                withAnimation(.easeIn(duration: 0.2)) { toastOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.4)) { toastOpacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showResult = false
                    }
                }
            }
        }
        .alert("Yetersiz Nakit", isPresented: $showInsufficientCash) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bu işlem için yeterli nakitiniz bulunmuyor.\nMevcut nakit: \(FormatUtils.tl(gameState.playerCash))")
        }
        .alert("Yüksek Zarar Uyarısı", isPresented: $showLossWarning) {
            Button("Evet, Devam Et", role: .destructive) {
                if let customer = gameState.currentCustomer {
                    commitOffer(offerValue: pendingOfferValue, customer: customer)
                }
            }
            Button("Hayır, Vazgeç", role: .cancel) { pendingOfferValue = 0 }
        } message: {
            let base = gameState.currentCustomer.map {
                gameState.calculateBaseValue(for: $0.request.items, direction: $0.request.direction)
            } ?? 0
            let lossPercent = base > 0 ? Int((1 - pendingOfferValue / base) * 100) : 0
            Text("Bu işlemden %\(lossPercent) veya daha fazla zarar edeceksiniz. Emin misiniz?")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gdlTextSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(gameState.activeShop?.name ?? "Dükkan")
                        .font(.gdlHeadline())
                        .foregroundColor(.gdlTextPrimary)
                    Text("Sıra: \(gameState.customerQueue.count) müşteri")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(FormatUtils.tlCompact(gameState.playerCash))
                            .font(.gdlHeadline()).foregroundColor(.gdlGold)
                        Text("Kâr: \(FormatUtils.tlCompact(gameState.dailyProfit))")
                            .font(.gdlCaption())
                            .foregroundColor(gameState.dailyProfit >= 0 ? .gdlPositive : .gdlNegative)
                    }
                    satisfactionBadge
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gdlCard)

            Rectangle().fill(Color.gdlGold.opacity(0.35)).frame(height: 2)
        }
    }

    private var satisfactionBadge: some View {
        VStack(spacing: 2) {
            Text("\(gameState.customerSatisfaction)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(satisfactionColor)
            Image(systemName: "face.smiling")
                .font(.caption)
                .foregroundColor(satisfactionColor)
        }
        .frame(width: 36)
    }

    // MARK: - Timer

    private func timerSection(customer: Customer) -> some View {
        VStack(spacing: 4) {
            TimerBar(progress: timeRemaining / Double(customer.patienceSeconds))
            HStack {
                Text("Müşteri sabrı")
                    .font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                Spacer()
                Text("\(Int(timeRemaining))s")
                    .font(.gdlCaption()).foregroundColor(timeRemaining < 10 ? .gdlNegative : .gdlTextSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Scene View (Interior + Customer)

    private func sceneView(customer: Customer) -> some View {
        let shopLocation = gameState.activeShop?.locationType.rawValue ?? "neighborhood"
        let hasInterior  = UIImage(named: "interior_\(shopLocation)") != nil
        let hasCustomer  = !customer.photoKey.isEmpty && UIImage(named: customer.photoKey) != nil

        return GeometryReader { geo in
            let W = geo.size.width
            let leftW = W * 0.58   // sol panel genişliği
            let rightW = W - leftW // müşteri alanı

            ZStack(alignment: .topLeading) {

                // Arka plan
                Rectangle().fill(Color(red: 0.10, green: 0.08, blue: 0.04))
                    .frame(width: W, height: 320)

                if hasInterior {
                    Image("interior_\(shopLocation)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: W, height: 320)
                        .clipped()
                } else {
                    Image(systemName: "storefront")
                        .font(.system(size: 48))
                        .foregroundColor(.gdlGold.opacity(0.2))
                        .frame(width: W, height: 320)
                }

                // Sol gradient — okunabilirlik
                LinearGradient(
                    colors: [Color.black.opacity(0.78), Color.black.opacity(0.35), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: W, height: 320)

                // Müşteri görseli — sağa yapışık, alta hizalı
                VStack(spacing: 0) {
                    Spacer()
                    if hasCustomer {
                        Image(customer.photoKey)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: rightW - 4, maxHeight: 315, alignment: .bottom)
                            .padding(.trailing, 20)
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 165)
                            .foregroundColor(.white.opacity(0.12))
                    }
                }
                .frame(width: rightW, height: 320)
                .offset(x: leftW)

                // Sol panel: timer + profil + diyalog + ürünler
                VStack(alignment: .leading, spacing: 0) {

                    // Timer bar
                    VStack(spacing: 3) {
                        TimerBar(progress: timeRemaining / Double(customer.patienceSeconds))
                        HStack {
                            Text("Müşteri sabrı")
                                .font(.gdlCaption())
                                .foregroundColor(.white.opacity(0.65))
                            Spacer()
                            Text("\(Int(timeRemaining))s")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(timeRemaining < 10 ? .gdlNegative : .white.opacity(0.65))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                    // Profil rozeti
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(customerTypeColor(customer).opacity(0.3))
                                .frame(width: 36, height: 36)
                            if hasCustomer {
                                Image(customer.photoKey)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Text(String(customer.name.prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(customerTypeColor(customer))
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(customer.customerType.displayName) · \(customer.age) yaş")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(9)
                    .padding(.horizontal, 10)

                    // Diyalog
                    Text(isBargainPhase
                         ? "Daha iyi bir teklif bekliyorum, ustam."
                         : customer.dialogue)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(9)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(9)
                        .padding(.horizontal, 10)
                        .padding(.top, 6)

                    // Ürün listesi
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(customer.request.items) { item in
                            HStack(spacing: 5) {
                                Image(systemName:
                                    customer.request.direction == .customerBuysFromPlayer
                                    ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(
                                        customer.request.direction == .customerBuysFromPlayer
                                        ? .gdlPositive : .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    if let rateInfo = rateLabel(for: item.productCategory) {
                                        Text(rateInfo)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)

                    Spacer()
                }
                .padding(.leading, 8)
                .frame(width: leftW)
            }
        }
        .frame(height: 320)
        .clipped()
    }

    private func customerTypeColor(_ customer: Customer) -> Color {
        switch customer.customerType {
        case .vip:      return .gdlGold
        case .generous: return .gdlPositive
        case .frugal:   return .orange
        case .urgent:   return .red
        case .tourist:  return .blue
        case .regular:  return .gdlTextSecondary
        }
    }

    private func rateLabel(for category: ProductCategory) -> String? {
        let key: String
        let label: String
        switch category {
        case .goldGram:     key = "gramGold";    label = "Gram Altın"
        case .goldQuarter:  key = "quarterGold"; label = "Çeyrek"
        case .goldHalf:     key = "halfGold";    label = "Yarım"
        case .goldFull:     key = "fullGold";    label = "Tam"
        case .currencyUSD:  key = "USD";         label = "USD"
        case .currencyEUR:  key = "EUR";         label = "EUR"
        case .jewelry:      key = "gramGold";    label = "Mücevher (g)"
        }
        guard let rate = gameState.rate(for: key) else { return nil }
        let price = (rate.buyPrice + rate.sellPrice) / 2.0
        return "Kur: \(FormatUtils.tl(price)) / \(label)"
    }

    // MARK: - Competitor Offers

    private func competitorOffersSection(customer: Customer) -> some View {
        let base = gameState.calculateBaseValue(for: customer.request.items, direction: customer.request.direction)
        _ = base  // used via competitorOffers state
        return VStack(alignment: .leading, spacing: 10) {
            Text("Aldığı Teklifler")
                .font(.gdlCaption())
                .foregroundColor(.gdlTextSecondary)

            ForEach(competitorOffers, id: \.name) { offer in
                HStack {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary)
                    Text(offer.name)
                        .font(.gdlBody())
                        .foregroundColor(.gdlTextPrimary)
                    Spacer()
                    Text(FormatUtils.tl(offer.price))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gdlGold)
                }
                .padding(.vertical, 2)

                if offer.name != competitorOffers.last?.name {
                    Divider().background(Color.gdlDivider)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.gdlBackground)
    }

    // MARK: - Keypad + Actions (combined compact block)

    private func keypadSection(customer: Customer) -> some View {
        VStack(spacing: 6) {
            // Amount display
            Text(offerInput.isEmpty ? "—" : FormatUtils.tl(Double(offerInput) ?? 0))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(offerInput.isEmpty ? .gdlTextSecondary : .gdlGold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)

            CompactNumericKeypad(input: $offerInput)

            // Action buttons inline
            HStack(spacing: 8) {
                Button(action: handleReject) {
                    Label("Reddet", systemImage: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.gdlNegative)
                        .cornerRadius(10)
                }
                .frame(maxWidth: 120)

                let hasStock = gameState.hasEnoughStock(for: customer.request.items, direction: customer.request.direction)
                Button(action: { handleOffer(customer: customer) }) {
                    Label("Teklif Ver", systemImage: hasStock ? "checkmark" : "archivebox.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(hasStock ? .white : .gdlTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(hasStock ? Color(red: 0.22, green: 0.60, blue: 0.35) : Color.gdlCardSecondary)
                        .cornerRadius(10)
                }
                .disabled(!hasStock)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.gdlBackground)
    }

    // MARK: - Empty Queue

    private var waitingForCustomerView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.gdlGold)
                .scaleEffect(1.4)
            Text("Yeni müşteri bekleniyor...")
                .font(.gdlBody())
                .foregroundColor(.gdlTextSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Result Overlay

    // MARK: - Toast Bildirimi

    private var resultToast: some View {
        HStack(spacing: 10) {
            Image(systemName: resultIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(resultColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(resultTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gdlTextPrimary)
                if lastResult == .accepted {
                    Text(lastProfit >= 0
                         ? "+\(FormatUtils.tl(lastProfit))"
                         : "-\(FormatUtils.tl(abs(lastProfit)))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(lastProfit >= 0 ? .gdlPositive : .gdlNegative)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gdlCard)
                .shadow(color: resultColor.opacity(0.35), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(resultColor.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var resultIcon: String {
        switch lastResult {
        case .accepted:  return lastProfit >= 0 ? "checkmark.circle.fill" : "minus.circle.fill"
        case .rejected:  return "xmark.circle.fill"
        case .bargained: return "bubble.left.fill"
        case .expired:   return "clock.fill"
        }
    }
    private var resultColor: Color {
        switch lastResult {
        case .accepted:  return lastProfit >= 0 ? .gdlPositive : .gdlNegative
        case .rejected:  return .gdlNegative
        case .bargained: return .orange
        case .expired:   return .gdlTextSecondary
        }
    }
    private var resultTitle: String {
        switch lastResult {
        case .accepted:  return "Anlaşma Tamam!"
        case .rejected:  return "Reddedildi"
        case .bargained: return "Müşteri Pazarlık İstiyor"
        case .expired:   return "Süre Doldu"
        }
    }

    // MARK: - Logic Handlers

    private func handleOffer(customer: Customer) {
        guard let offerValue = Double(offerInput), offerValue > 0 else { return }

        // Nakit yetersizlik kontrolü (müşteri satıyor → oyuncu ödüyor)
        if customer.request.direction == .customerSellsToPlayer {
            guard offerValue <= gameState.playerCash else {
                showInsufficientCash = true
                return
            }
        }

        // Envanter yetersizlik kontrolü (oyuncu satıyor)
        guard gameState.hasEnoughStock(for: customer.request.items, direction: customer.request.direction) else {
            lastResult = .rejected
            showResult = true
            gameState.processRejectedTransaction()
            return
        }

        // %10+ zarar uyarısı
        let base = gameState.calculateBaseValue(for: customer.request.items, direction: customer.request.direction)
        if base > 0 {
            let isLoss: Bool
            switch customer.request.direction {
            case .customerBuysFromPlayer:
                // Oyuncu satıyor, çok ucuza veriyorsa zarar
                isLoss = offerValue < base * 0.90
            case .customerSellsToPlayer:
                // Oyuncu alıyor, çok pahalıya alıyorsa zarar
                isLoss = offerValue > base * 1.10
            }
            if isLoss {
                pendingOfferValue = offerValue
                showLossWarning = true
                return
            }
        }

        commitOffer(offerValue: offerValue, customer: customer)
    }

    private func commitOffer(offerValue: Double, customer: Customer) {
        let result = gameState.evaluateOffer(
            offer: offerValue,
            customer: customer,
            direction: customer.request.direction,
            items: customer.request.items
        )
        switch result {
        case .accepted:
            let base = gameState.calculateBaseValue(for: customer.request.items, direction: customer.request.direction)
            lastProfit = customer.request.direction == .customerBuysFromPlayer ? offerValue - base : base - offerValue
            lastResult = .accepted
            showResult = true
            gameState.processAcceptedTransaction(offer: offerValue, direction: customer.request.direction, items: customer.request.items)

        case .bargained:
            lastResult = .bargained
            showResult = true
            gameState.processBargain()
            isBargainPhase = true

        case .rejected:
            lastResult = .rejected
            showResult = true
            gameState.processRejectedTransaction()

        case .expired:
            break
        }
    }

    private func handleReject() {
        lastResult = .rejected
        showResult = true
        gameState.processRejectedTransaction()
    }

    private func handleTimerExpired() {
        lastResult = .expired
        showResult = true
        gameState.processTimerExpired()
    }

    private func resetForNewCustomer() {
        offerInput = ""
        isBargainPhase = false
        if let customer = gameState.currentCustomer {
            timeRemaining = Double(customer.patienceSeconds)
            generateCompetitorOffers(for: customer)
        }
    }

    private func generateCompetitorOffers(for customer: Customer) {
        let base = gameState.calculateBaseValue(for: customer.request.items, direction: customer.request.direction)
        let picked = Array(competitorNames.shuffled().prefix(3))
        competitorOffers = picked.map { name in
            let variation: Double
            switch customer.request.direction {
            case .customerBuysFromPlayer:
                variation = Double.random(in: -0.05...0.0)
            case .customerSellsToPlayer:
                variation = Double.random(in: 0.0...0.05)
            }
            let rawPrice = base * (1.0 + variation)
            let rounded  = (rawPrice / 100).rounded() * 100
            return (name: name, price: rounded)
        }
    }

    private var satisfactionColor: Color {
        if gameState.customerSatisfaction >= 70 { return .gdlPositive }
        if gameState.customerSatisfaction >= 40 { return .orange }
        return .gdlNegative
    }
}

#Preview {
    CounterView().environmentObject(GameState())
}
