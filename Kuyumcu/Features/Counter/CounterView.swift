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
        GeometryReader { proxy in
            let availableHeight = proxy.size.height
            let compactLayout = availableHeight < 850

            ZStack {
                VStack(spacing: 0) {
                    topBar(isCompact: compactLayout)

                    if let customer = gameState.currentCustomer {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: GDLSpacing.xs) {
                                summaryBar
                                    .padding(.horizontal, GDLSpacing.md)
                                sceneView(customer: customer, availableHeight: availableHeight, isCompact: compactLayout)
                                    .padding(.horizontal, GDLSpacing.md)
                                    .overlay(alignment: .bottom) {
                                        if showResult {
                                            resultToast
                                                .opacity(toastOpacity)
                                                .animation(.easeInOut(duration: 0.25), value: toastOpacity)
                                        }
                                    }
                                competitorOffersSection(customer: customer)
                                    .padding(.horizontal, GDLSpacing.md)
                            }
                            .padding(.top, GDLSpacing.md)
                            .padding(.bottom, compactLayout ? GDLSpacing.md : GDLSpacing.lg)
                        }
                    } else {
                        waitingForCustomerView
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let customer = gameState.currentCustomer {
                    keypadSection(customer: customer, isCompact: compactLayout)
                        .padding(.horizontal, GDLSpacing.md)
                        .padding(.top, GDLSpacing.sm)
                        .padding(.bottom, GDLSpacing.sm)
                        .background(.ultraThinMaterial.opacity(0.08))
                }
            }
        }
        .gdlScreenBackground()
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

    private func topBar(isCompact: Bool) -> some View {
        HStack(alignment: .top, spacing: GDLSpacing.md) {
            Button {
                audioManager.playEffect(.buttonTap)
                dismiss()
            } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gdlTextPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.gdlCardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: GDLRadius.md))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 0) {
                Text(gameState.activeShop?.name ?? "Dükkan")
                    .font(.gdlTitle())
                    .foregroundColor(.gdlTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("\(queueCountText) bekleyen müşteri")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                    .lineLimit(1)
            }
            .frame(height: 44, alignment: .center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, GDLSpacing.md)
        .padding(.top, GDLSpacing.xxs)
        .padding(.bottom, GDLSpacing.xxs)
    }

    private var queueCountText: String {
        let count = max(0, gameState.customerQueue.count - (gameState.currentCustomer == nil ? 0 : 1))
        return "\(count)"
    }

    private var summaryBar: some View {
        HStack(spacing: 0) {
            summaryItem(icon: "turkishlirasign.circle.fill", label: "Nakit", value: FormatUtils.tlCompact(gameState.playerCash), valueColor: .gdlGold)
            Divider().background(Color.gdlDivider)
            summaryItem(icon: "chart.line.uptrend.xyaxis", label: "Kâr", value: FormatUtils.tlCompact(gameState.dailyProfit), valueColor: gameState.dailyProfit >= 0 ? .gdlPositive : .gdlNegative)
            Divider().background(Color.gdlDivider)
            summaryItem(icon: "person.3.fill", label: "Sıra", value: "\(max(0, gameState.customerQueue.count))", valueColor: .gdlTextPrimary)
        }
        .padding(.horizontal, GDLSpacing.sm)
        .padding(.top, GDLSpacing.xs)
        .padding(.bottom, GDLSpacing.xs)
        .background(Color.gdlCard)
        .overlay(
            RoundedRectangle(cornerRadius: GDLRadius.lg)
                .stroke(Color.gdlStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.lg))
    }

    private func summaryItem(icon: String, label: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: GDLSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gdlGold)
            Text("\(label):")
                .font(.gdlCaption())
                .foregroundColor(.gdlTextSecondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timer

    private func timerSection(customer: Customer) -> some View {
        VStack(spacing: GDLSpacing.xxs) {
            TimerBar(progress: timeRemaining / Double(customer.patienceSeconds))
            HStack {
                Text("Müşteri sabrı")
                    .font(.gdlCaption()).foregroundColor(.white.opacity(0.65))
                Spacer()
                Text("\(Int(timeRemaining))s")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeRemaining < 10 ? .gdlNegative : .white.opacity(0.72))
            }
        }
    }

    // MARK: - Scene View (Interior + Customer)

    private func sceneView(customer: Customer, availableHeight: CGFloat, isCompact: Bool) -> some View {
        let shopLocation = gameState.activeShop?.locationType.rawValue ?? "neighborhood"
        let hasInterior  = UIImage(named: "interior_\(shopLocation)") != nil
        let hasCustomer  = !customer.photoKey.isEmpty && UIImage(named: customer.photoKey) != nil
        let sceneHeight = min(max(availableHeight * (isCompact ? 0.36 : 0.40), isCompact ? 268 : 300), isCompact ? 320 : 380)

        return GeometryReader { geo in
            let W = geo.size.width
            let leftW = W * 0.56
            let rightW = W - leftW

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: GDLRadius.xxl)
                    .fill(Color(red: 0.10, green: 0.08, blue: 0.04))
                    .frame(width: W, height: sceneHeight)

                if hasInterior {
                    Image("interior_\(shopLocation)")
                        .resizable()
                        .scaledToFill()
                        .frame(width: W, height: sceneHeight)
                        .clipped()
                } else {
                    Image(systemName: "storefront")
                        .font(.system(size: 48))
                        .foregroundColor(.gdlGold.opacity(0.2))
                        .frame(width: W, height: sceneHeight)
                }

                LinearGradient(
                    colors: [Color.black.opacity(0.82), Color.black.opacity(0.44), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: W, height: sceneHeight)

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.48)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: W, height: sceneHeight)

                VStack(spacing: 0) {
                    Spacer()
                    if hasCustomer {
                        Image(customer.photoKey)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: rightW - 8, maxHeight: sceneHeight - 14, alignment: .bottom)
                            .padding(.trailing, GDLSpacing.lg + GDLSpacing.xxxs)
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: sceneHeight * 0.48)
                            .foregroundColor(.white.opacity(0.12))
                    }
                }
                .frame(width: rightW, height: sceneHeight)
                .offset(x: leftW)

                VStack(alignment: .leading, spacing: 0) {
                    timerSection(customer: customer)
                        .padding(.horizontal, GDLSpacing.md)
                        .padding(.top, GDLSpacing.md)

                    HStack(spacing: GDLSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(customerTypeColor(customer).opacity(0.3))
                                .frame(width: 42, height: 42)
                            if hasCustomer {
                                Image(customer.photoKey)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 42, height: 42)
                                    .clipShape(Circle())
                            } else {
                                Text(String(customer.name.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(customerTypeColor(customer))
                            }
                        }

                        VStack(alignment: .leading, spacing: GDLSpacing.xxxs) {
                            Text(customer.name)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            HStack(spacing: GDLSpacing.xs) {
                                Text(customer.customerType.displayName)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(customerTypeColor(customer))
                                Text("·")
                                    .foregroundColor(.white.opacity(0.45))
                                Text("\(customer.age) yaş")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                    }
                    .padding(.horizontal, GDLSpacing.sm)
                    .padding(.vertical, GDLSpacing.sm)
                    .background(Color.black.opacity(0.46))
                    .clipShape(RoundedRectangle(cornerRadius: GDLRadius.md))
                    .padding(.horizontal, GDLSpacing.md)
                    .padding(.top, GDLSpacing.sm)

                    Text(isBargainPhase
                         ? "Daha iyi bir teklif bekliyorum, ustam."
                         : customer.dialogue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(GDLSpacing.sm)
                        .background(Color.black.opacity(0.52))
                        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.md))
                        .padding(.horizontal, GDLSpacing.md)
                        .padding(.top, GDLSpacing.sm)

                    VStack(alignment: .leading, spacing: GDLSpacing.xs) {
                        ForEach(customer.request.items) { item in
                            HStack(spacing: GDLSpacing.xs) {
                                Image(systemName:
                                    customer.request.direction == .customerBuysFromPlayer
                                    ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(
                                        customer.request.direction == .customerBuysFromPlayer
                                        ? .gdlPositive : .orange)
                                VStack(alignment: .leading, spacing: GDLSpacing.xxxs) {
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
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(GDLSpacing.sm)
                    .background(Color.black.opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: GDLRadius.md))
                    .padding(.horizontal, GDLSpacing.md)
                    .padding(.top, GDLSpacing.sm)

                    Spacer()
                }
                .frame(width: leftW)
            }
        }
        .frame(height: sceneHeight)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: GDLRadius.xxl)
                .stroke(Color.gdlStroke, lineWidth: 1)
        )
        .shadow(color: .gdlShadow, radius: 18, x: 0, y: 10)
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
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                ForEach(competitorOffers, id: \.name) { offer in
                    HStack {
                        Text(offer.name)
                            .font(.gdlBody())
                            .foregroundColor(.gdlTextPrimary)
                        Spacer()
                        Text(FormatUtils.tl(offer.price))
                            .font(.gdlBody())
                            .foregroundColor(.gdlGold)
                    }
                    .padding(.vertical, GDLSpacing.sm)

                    if offer.name != competitorOffers.last?.name {
                        Divider().background(Color.gdlDivider)
                    }
                }
            }
            .padding(.horizontal, GDLSpacing.md)
            .padding(.vertical, GDLSpacing.sm)
            .background(Color.gdlCard)
            .overlay(
                RoundedRectangle(cornerRadius: GDLRadius.lg)
                    .stroke(Color.gdlStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.lg))
        }
    }

    // MARK: - Keypad + Actions (combined compact block)

    private func keypadSection(customer: Customer, isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? GDLSpacing.sm : GDLSpacing.md) {
            Text(offerInput.isEmpty ? "—" : FormatUtils.tl(Double(offerInput) ?? 0))
                .font(.system(size: isCompact ? 23 : 26, weight: .bold, design: .rounded))
                .foregroundColor(offerInput.isEmpty ? .gdlTextSecondary : .gdlGold)
                .frame(maxWidth: .infinity, alignment: .center)

            CompactNumericKeypad(input: $offerInput)

            let hasStock = gameState.hasEnoughStock(for: customer.request.items, direction: customer.request.direction)
            HStack(spacing: 5) {
                Button {
                    handleReject()
                } label: {
                    HStack(spacing: GDLSpacing.xs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Reddet")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.gdlTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.gdlNegative)
                    .clipShape(RoundedRectangle(cornerRadius: GDLSpacing.sm))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                Button {
                    handleOffer(customer: customer)
                } label: {
                    HStack(spacing: GDLSpacing.xs) {
                        Image(systemName: hasStock ? "checkmark" : "archivebox.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Teklif Ver")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(hasStock ? .gdlTextPrimary : .gdlTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(hasStock ? Color.gdlPositive : Color.gdlCardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: GDLSpacing.sm))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .disabled(!hasStock)
            }
        }
        .padding(GDLSpacing.md)
        .background(Color.gdlCard)
        .overlay(
            RoundedRectangle(cornerRadius: GDLRadius.lg)
                .stroke(Color.gdlStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.lg))
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
        .padding(.horizontal, 24)
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
        audioManager.playEffect(.buttonTap)

        // Nakit yetersizlik kontrolü (müşteri satıyor → oyuncu ödüyor)
        if customer.request.direction == .customerSellsToPlayer {
            guard offerValue <= gameState.playerCash else {
                audioManager.playEffect(.dealFail)
                showInsufficientCash = true
                return
            }
        }

        // Envanter yetersizlik kontrolü (oyuncu satıyor)
        guard gameState.hasEnoughStock(for: customer.request.items, direction: customer.request.direction) else {
            audioManager.playEffect(.dealFail)
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
            if gameState.processAcceptedTransaction(offer: offerValue, direction: customer.request.direction, items: customer.request.items) {
                let base = gameState.calculateBaseValue(for: customer.request.items, direction: customer.request.direction)
                lastProfit = customer.request.direction == .customerBuysFromPlayer ? offerValue - base : base - offerValue
                audioManager.playEffect(.dealSuccess)
                lastResult = .accepted
                showResult = true
            } else {
                lastProfit = 0
                audioManager.playEffect(.dealFail)
                lastResult = .rejected
                showResult = true
            }

        case .bargained:
            audioManager.playEffect(.bargain)
            lastResult = .bargained
            showResult = true
            gameState.processBargain()
            isBargainPhase = true

        case .rejected:
            audioManager.playEffect(.dealFail)
            lastResult = .rejected
            showResult = true
            gameState.processRejectedTransaction()

        case .expired:
            break
        }
    }

    private func handleReject() {
        audioManager.playEffect(.dealFail)
        lastResult = .rejected
        showResult = true
        gameState.processRejectedTransaction()
    }

    private func handleTimerExpired() {
        audioManager.playEffect(.dealFail)
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
}

#Preview {
    CounterView().environmentObject(GameState())
}
