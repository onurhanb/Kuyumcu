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
            VStack(spacing: 6) {
                // Dış yuvarlak
                ZStack {
                    Circle()
                        .fill(status.circleFill)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .strokeBorder(status.borderColor, lineWidth: status == .available ? 2.5 : 0)
                        )

                    // İç yuvarlak
                    Circle()
                        .fill(status.innerCircleFill)
                        .frame(width: 30, height: 30)

                    // İç icon
                    if status == .claimed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text("\(day). gün")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(status.textColor)

                Text(rewardLabel(reward))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(status == .available ? .gdlGold : status.textColor)
            }
            .frame(width: 54)
        }
        .disabled(status != .available)
    }

    // MARK: - Helpers

    private enum CellStatus {
        case claimed    // alındı
        case available  // bu gün aktif, alınabilir
        case locked     // henüz gelmedi

        var circleFill: Color {
            switch self {
            case .claimed:   return Color.gray.opacity(0.20)
            case .available: return Color.gdlGold.opacity(0.15)
            case .locked:    return Color.gdlCardSecondary
            }
        }
        var innerCircleFill: Color {
            switch self {
            case .claimed:   return Color.gray.opacity(0.50)
            case .available: return Color.gdlGold
            case .locked:    return Color.gray.opacity(0.20)
            }
        }
        var borderColor: Color {
            switch self {
            case .available: return Color.gdlGold
            default: return Color.clear
            }
        }
        var textColor: Color {
            switch self {
            case .claimed:   return .gray
            case .available: return .gdlTextPrimary
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
