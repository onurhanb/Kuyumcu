import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var gameState: GameState

    enum Tab: String, CaseIterable {
        case daily    = "Günlük Kâr"
        case weekly   = "Haftalık Kâr"
        case monthly  = "Aylık Ciro"
        case netWorth = "Toplam Servet"
    }

    @State private var selectedTab: Tab = .daily

    // Fixed UUID so the player row keeps stable identity across renders (prevents animation jumps)
    private let playerID = UUID()

    private var playerEntry: LeaderboardEntry {
        LeaderboardEntry(
            id: playerID,
            playerName: "Sen (Benim Dükkanım)",
            dailyProfit: gameState.dailyProfit,
            weeklyProfit: gameState.weeklyProfit,
            monthlyRevenue: gameState.monthlyRevenue,
            netWorth: gameState.totalNetWorth,
            isPlayer: true
        )
    }

    private var sortedEntries: [LeaderboardEntry] {
        var entries = MockGameData.mockLeaderboard
        entries.append(playerEntry)
        switch selectedTab {
        case .daily:    return entries.sorted { $0.dailyProfit    > $1.dailyProfit }
        case .weekly:   return entries.sorted { $0.weeklyProfit   > $1.weeklyProfit }
        case .monthly:  return entries.sorted { $0.monthlyRevenue > $1.monthlyRevenue }
        case .netWorth: return entries.sorted { $0.netWorth       > $1.netWorth }
        }
    }

    private func valueForTab(_ entry: LeaderboardEntry) -> Double {
        switch selectedTab {
        case .daily:    return entry.dailyProfit
        case .weekly:   return entry.weeklyProfit
        case .monthly:  return entry.monthlyRevenue
        case .netWorth: return entry.netWorth
        }
    }

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()
            VStack(spacing: 0) {

                // Tab picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                Text(tab.rawValue)
                                    .font(.gdlCaption())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(selectedTab == tab ? Color.gdlGold : Color.gdlCard)
                                    .foregroundColor(selectedTab == tab ? .black : .gdlTextPrimary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.gdlCard)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { rank, entry in
                            leaderboardRow(rank: rank + 1, entry: entry, value: valueForTab(entry))
                        }
                        Text("Çevrimiçi sıralama yakında aktif olacak.")
                            .font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                            .padding(.top, 8)
                        Spacer(minLength: 80)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Sıralama")
        .navigationBarTitleDisplayMode(.large)
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry, value: Double) -> some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 36, height: 36)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rank <= 3 ? .black : .white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName)
                    .font(.gdlBody())
                    .foregroundColor(entry.isPlayer ? .gdlGold : .gdlTextPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Text(FormatUtils.tlCompact(value))
                .font(.gdlHeadline())
                .foregroundColor(entry.isPlayer ? .gdlGold : .gdlTextPrimary)
        }
        .padding(12)
        .background(entry.isPlayer ? Color.gdlGold.opacity(0.1) : Color.gdlCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isPlayer ? Color.gdlGold.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)   // gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // silver
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20) // bronze
        default: return Color.gdlCardSecondary
        }
    }
}

#Preview {
    NavigationStack { LeaderboardView().environmentObject(GameState()) }
}
