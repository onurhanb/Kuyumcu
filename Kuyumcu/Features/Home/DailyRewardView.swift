import SwiftUI

struct DailyRewardView: View {
    @EnvironmentObject var gameState: GameState
    @Binding var isPresented: Bool

    @State private var claimedThisSession  = false
    @State private var showConfetti        = false
    @State private var showAdNotReadyAlert = false

    private var availableDay: Int    { gameState.dailyRewardAvailableDay }
    private var claimedToday: Bool   { gameState.dailyRewardClaimedToday }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Arka plan karartma
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Kart
            VStack(spacing: 0) {

                // Başlık
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.gdlGold)
                    Text("Günlük Ödül")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.gdlTextPrimary)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gdlTextSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 14)

                Divider().background(Color.gdlDivider)

                // Açıklama
                Text("Her gün giriş yaparak ödüller kazan. Eğer bir gün atlarsan başa dönersin!")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                // 7 gün tek satır
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(1...7, id: \.self) { day in
                            dayCell(day: day)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 22)

                Text("* Kısa bir reklam videosundan sonra ödül verilecektir.")
                    .font(.system(size: 11))
                    .foregroundColor(.gdlTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
            .background(Color.gdlCard)
            .cornerRadius(20)
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
            .alert("Reklam Hazır Değil", isPresented: $showAdNotReadyAlert) {
                Button("Tamam") { AdManager.shared.loadAd() }
            } message: {
                Text("Reklam henüz yüklenmedi. Birkaç saniye bekleyip tekrar dene.")
            }
        }
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(day: Int) -> some View {
        let status = cellStatus(day: day)
        let reward = GameState.dailyRewardAmounts[day] ?? 0

        Button {
            guard status == .available else { return }
            if AdManager.shared.isAdReady {
                AdManager.shared.showAd {
                    gameState.claimDailyReward()
                    claimedThisSession = true
                }
            } else {
                AdManager.shared.loadAd()
                showAdNotReadyAlert = true
            }
        } label: {
            VStack(spacing: 7) {
                Text(rewardLabel(reward))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(status.amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 72, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(status.boxFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(status.borderColor, lineWidth: status == .available ? 1.5 : 1)
                    )

                Text("\(day). Gün")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(status.dayTextColor)
            }
            .frame(width: 72)
        }
        .disabled(status != .available)
    }

    // MARK: - Helpers

    private enum CellStatus {
        case claimed    // alındı
        case available  // bu gün aktif, alınabilir
        case locked     // henüz gelmedi

        var boxFill: Color {
            switch self {
            case .claimed:   return Color.gdlGold.opacity(0.16)
            case .available: return Color.gdlGold
            case .locked:    return Color.gdlCardSecondary
            }
        }

        var borderColor: Color {
            switch self {
            case .claimed:   return Color.gdlGold.opacity(0.22)
            case .available: return Color.gdlGold.opacity(0.95)
            case .locked:    return Color.gdlDivider.opacity(0.7)
            }
        }

        var amountColor: Color {
            switch self {
            case .claimed:   return Color.gdlGold.opacity(0.78)
            case .available: return .black
            case .locked:    return .gdlTextSecondary
            }
        }

        var dayTextColor: Color {
            switch self {
            case .claimed:   return Color.gdlGold.opacity(0.55)
            case .available: return Color.black.opacity(0.72)
            case .locked:    return .gdlTextSecondary
            }
        }
    }

    private func cellStatus(day: Int) -> CellStatus {
        // Alındı mı?
        if claimedToday && day == availableDay { return .claimed }
        if day < availableDay                  { return .claimed }
        // Bu gün mü?
        if day == availableDay && !claimedToday { return .available }
        // Kilit
        return .locked
    }

    private func rewardLabel(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.0fM ₺", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.0fK ₺", amount / 1_000)
        }
        return FormatUtils.tl(amount)
    }
}
