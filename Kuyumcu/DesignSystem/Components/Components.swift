import SwiftUI

// MARK: - GoldButton

struct GoldButton: View {
    enum Style { case primary, secondary, destructive }

    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var isDisabled: Bool = false
    let action: () -> Void

    init(_ title: String, icon: String? = nil, style: Style = .primary, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    private var bg: Color {
        if isDisabled { return Color(white: 0.25) }
        switch style {
        case .primary:     return .gdlGold
        case .secondary:   return .gdlCard
        case .destructive: return .gdlNegative
        }
    }
    private var fg: Color {
        if isDisabled { return .gdlTextSecondary }
        switch style {
        case .primary: return .black
        default:       return .white
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .font(.gdlBody())
            .foregroundColor(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(bg)
            .cornerRadius(12)
        }
        .disabled(isDisabled)
    }
}

// MARK: - StatPill

struct StatPill: View {
    let label: String
    let value: String
    var icon: String? = nil
    var valueColor: Color = .gdlTextPrimary

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.caption).foregroundColor(.gdlGold) }
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                Text(value).font(.gdlHeadline()).foregroundColor(valueColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gdlCard)
        .cornerRadius(10)
    }
}

// MARK: - SectionCard

struct SectionCard<Content: View>: View {
    let title: String
    var icon: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).foregroundColor(.gdlGold) }
                Text(title).font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
            }
            content()
        }
        .padding(14)
        .gdlCard()
    }
}

// MARK: - RateRow

struct RateRow: View {
    let rate: Rate

    var body: some View {
        HStack {
            Text(rate.name)
                .font(.gdlBody())
                .foregroundColor(.gdlTextPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Alış: \(FormatUtils.tl(rate.buyPrice))")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                Text("Satış: \(FormatUtils.tl(rate.sellPrice))")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlGold)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - EventBanner

struct EventBanner: View {
    let event: GameEvent

    private var accent: Color {
        switch event.eventType {
        case .weddingSeason:  return Color.pink
        case .holiday:        return Color.orange
        case .touristSeason:  return Color.blue
        case .promotionWeek:  return .gdlPositive
        case .financeNews:    return .gdlNegative
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.eventType.icon)
                .font(.title3)
                .foregroundColor(accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.gdlHeadline())
                    .foregroundColor(.gdlTextPrimary)
                Text(event.description)
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(event.remainingDays) gün")
                    .font(.gdlCaption())
                    .foregroundColor(accent)
                Text("kaldı")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
            }
        }
        .padding(12)
        .background(accent.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.3), lineWidth: 1))
        .cornerRadius(12)
    }
}

// MARK: - ShopCard

struct ShopCard: View {
    let shop: Shop
    var playerCash: Double = 0
    var onBuy: (() -> Void)? = nil
    var onHire: (() -> Void)? = nil

    var canAfford: Bool { playerCash >= shop.purchasePrice }
    var canHire: Bool { shop.isOwned && shop.employeeCount < shop.employeeCapacity && playerCash >= shop.locationType.employeeHireCost }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Dükkan iç görsel (varsa)
            let imageName = "interior_\(shop.locationType.rawValue)"
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .clipped()
                    .cornerRadius(10)
            }

            // Üst satır: ikon + isim/konum + buton
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: shop.locationType.icon)
                    .font(.title2)
                    .foregroundColor(.gdlGold)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(shop.name)
                        .font(.gdlHeadline())
                        .foregroundColor(.gdlTextPrimary)
                    Text(shop.description)
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }

                Spacer()

                // Satın Al / Mevcut butonu
                if shop.isOwned {
                    Label("Mevcut", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.60, blue: 0.35))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.22, green: 0.60, blue: 0.35).opacity(0.12))
                        .cornerRadius(10)
                } else if let onBuy {
                    Button(action: onBuy) {
                        Text("Satın Al")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(canAfford ? .black : .gdlTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(canAfford ? Color.gdlGold : Color.gdlCardSecondary)
                            .cornerRadius(10)
                    }
                    .disabled(!canAfford)
                }
            }

            Divider().background(Color.gdlDivider)

            // Alt satır: istatistikler (fiyat dahil)
            HStack(spacing: 16) {
                if !shop.isOwned {
                    shopStat(label: "Fiyat", value: FormatUtils.tlCompact(shop.purchasePrice), color: canAfford ? .gdlGold : .gdlNegative)
                }
                shopStat(label: "Günlük Pasif", value: FormatUtils.tlCompact(shop.dailyPassiveBaseIncome), color: .gdlGold)
                shopStat(label: "VIP", value: "\(Int(shop.vipChance * 100))%", color: .gdlTextPrimary)

                // Personel stat + hire butonu
                VStack(alignment: .leading, spacing: 2) {
                    Text("Personel")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                    HStack(spacing: 4) {
                        Text("\(shop.employeeCount)/\(shop.employeeCapacity)")
                            .font(.gdlBody())
                            .foregroundColor(.gdlTextPrimary)
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.gdlTextSecondary)
                        if shop.isOwned && shop.employeeCount < shop.employeeCapacity {
                            Button(action: { onHire?() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(canHire ? .gdlGold : .gdlTextSecondary)
                            }
                            .disabled(!canHire)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(14)
        .gdlCard()
    }

    private func shopStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.gdlCaption())
                .foregroundColor(.gdlTextSecondary)
            Text(value)
                .font(.gdlBody())
                .foregroundColor(color)
        }
    }
}

// MARK: - CustomerCard

struct CustomerCard: View {
    let customer: Customer

    private var typeColor: Color {
        switch customer.customerType {
        case .vip:      return .gdlGold
        case .generous: return .gdlPositive
        case .frugal:   return .orange
        case .urgent:   return .red
        case .tourist:  return .blue
        case .regular:  return .gdlTextSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Avatar placeholder
                ZStack {
                    Circle().fill(typeColor.opacity(0.2)).frame(width: 48, height: 48)
                    Text(String(customer.name.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(typeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(customer.name)
                            .font(.gdlHeadline())
                            .foregroundColor(.gdlTextPrimary)
                        Text("·")
                            .foregroundColor(.gdlTextSecondary)
                        Text("\(customer.age) yaş")
                            .font(.gdlBody())
                            .foregroundColor(.gdlTextSecondary)
                    }
                    HStack(spacing: 6) {
                        Text(customer.trait)
                            .font(.gdlCaption())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(typeColor.opacity(0.15))
                            .foregroundColor(typeColor)
                            .cornerRadius(6)
                        Text(customer.customerType.displayName)
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                    }
                }
                Spacer()

                // Direction badge
                VStack(spacing: 2) {
                    Image(systemName: customer.request.direction == .customerBuysFromPlayer ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(customer.request.direction == .customerBuysFromPlayer ? .gdlPositive : .orange)
                        .font(.title2)
                    Text(customer.request.direction.displayName)
                        .font(.gdlCaption())
                        .foregroundColor(.gdlTextSecondary)
                }
            }

            Divider().background(Color.gdlDivider)

            ForEach(customer.request.items) { item in
                HStack {
                    Image(systemName: "diamond.fill").font(.caption).foregroundColor(.gdlGold)
                    Text(item.label)
                        .font(.gdlBody())
                        .foregroundColor(.gdlTextPrimary)
                }
            }
        }
        .padding(14)
        .gdlCard()
    }
}

// MARK: - DialogueBubble

struct DialogueBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundColor(.gdlGold)
                .frame(width: 32, height: 32)
                .background(Color.gdlGold.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.gdlBody())
                .foregroundColor(.gdlTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(Color.gdlCardSecondary)
                .cornerRadius(12)

            Spacer()
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - NumericKeypad

struct NumericKeypad: View {
    @Binding var input: String

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(label: key) { tapped(key) }
                    }
                }
            }
        }
    }

    private func tapped(_ key: String) {
        switch key {
        case "C":  input = ""
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        default:
            // Max 12 digits
            if input.count < 12 { input += key }
        }
    }
}

private struct KeypadButton: View {
    let label: String
    let action: () -> Void

    private var isAction: Bool { label == "C" || label == "⌫" }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(isAction ? .gdlNegative : .gdlTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.gdlCard)
                .cornerRadius(12)
        }
    }
}

// MARK: - CompactNumericKeypad

struct CompactNumericKeypad: View {
    @Binding var input: String

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { key in
                        CompactKeypadButton(label: key) { tappedKey(key) }
                    }
                }
            }
        }
    }

    private func tappedKey(_ key: String) {
        switch key {
        case "C":  input = ""
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        default:
            if input.count < 12 { input += key }
        }
    }
}

private struct CompactKeypadButton: View {
    let label: String
    let action: () -> Void

    private var isAction: Bool { label == "C" || label == "⌫" }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(isAction ? .gdlNegative : .gdlTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.gdlBackground)
                .cornerRadius(8)
        }
    }
}

// MARK: - TransactionSummaryCard

struct TransactionSummaryCard: View {
    let direction: TransactionDirection
    let items: [RequestItem]
    let baseValue: Double
    let offerText: String
    var insufficientStock: Bool = false

    private var offerAmount: Double { Double(offerText) ?? 0 }

    private var profitEstimate: Double {
        switch direction {
        case .customerBuysFromPlayer: return offerAmount - baseValue
        case .customerSellsToPlayer:  return baseValue - offerAmount
        }
    }

    private var profitColor: Color {
        profitEstimate > 0 ? .gdlPositive : (profitEstimate < 0 ? .gdlNegative : .gdlTextSecondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "function")
                    .foregroundColor(.gdlGold)
                Text("İşlem Özeti")
                    .font(.gdlHeadline())
                    .foregroundColor(.gdlTextPrimary)
            }

            ForEach(items) { item in
                HStack {
                    Text(item.label)
                        .font(.gdlBody())
                        .foregroundColor(.gdlTextSecondary)
                    Spacer()
                }
            }

            Divider().background(Color.gdlDivider)

            HStack {
                Text("Piyasa Değeri")
                    .font(.gdlBody())
                    .foregroundColor(.gdlTextSecondary)
                Spacer()
                Text(FormatUtils.tl(baseValue))
                    .font(.gdlHeadline())
                    .foregroundColor(.gdlTextPrimary)
            }

            HStack {
                Text("Teklifiniz")
                    .font(.gdlBody())
                    .foregroundColor(.gdlTextSecondary)
                Spacer()
                Text(offerAmount > 0 ? FormatUtils.tl(offerAmount) : "—")
                    .font(.gdlHeadline())
                    .foregroundColor(.gdlGold)
            }

            if offerAmount > 0 {
                HStack {
                    Text("Tahmini Kâr")
                        .font(.gdlBody())
                        .foregroundColor(.gdlTextSecondary)
                    Spacer()
                    Text(FormatUtils.tl(profitEstimate))
                        .font(.gdlHeadline())
                        .foregroundColor(profitColor)
                }
            }

            if insufficientStock {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.gdlNegative)
                        .font(.caption)
                    Text("Envanterde yeterli ürün yok!")
                        .font(.gdlCaption())
                        .foregroundColor(.gdlNegative)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gdlNegative.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .gdlCard()
    }
}

// MARK: - TimerBar

struct TimerBar: View {
    let progress: Double   // 0.0 → 1.0 (1.0 = full time remaining)

    private var barColor: Color {
        if progress > 0.5 { return .gdlPositive }
        if progress > 0.25 { return .orange }
        return .gdlNegative
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gdlDivider)
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(.linear(duration: 0.5), value: progress)
            }
        }
        .frame(height: 6)
    }
}
