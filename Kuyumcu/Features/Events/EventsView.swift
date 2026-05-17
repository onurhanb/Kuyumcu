import SwiftUI

struct EventsView: View {
    @EnvironmentObject var gameState: GameState

    private var activeEvents: [GameEvent] { gameState.activeEvents.filter { $0.isActive } }
    private var upcomingEvents: [GameEvent] { gameState.activeEvents.filter { !$0.isActive } }

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    if !activeEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Aktif Etkinlikler")
                                .font(.gdlHeadline()).foregroundColor(.gdlGold)
                                .padding(.horizontal)
                            ForEach(activeEvents) { event in
                                eventDetailCard(event: event, isActive: true)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Yaklaşan / Geçmiş Etkinlikler")
                            .font(.gdlHeadline()).foregroundColor(.gdlTextSecondary)
                            .padding(.horizontal)
                        ForEach(upcomingEvents) { event in
                            eventDetailCard(event: event, isActive: false)
                                .padding(.horizontal)
                                .opacity(0.6)
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Etkinlikler")
        .navigationBarTitleDisplayMode(.large)
    }

    private func eventDetailCard(event: GameEvent, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: event.eventType.icon)
                    .font(.title2)
                    .foregroundColor(eventColor(event))
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
                    Text(isActive ? "\(event.remainingDays) gün kaldı" : "Pasif")
                        .font(.gdlCaption())
                        .foregroundColor(isActive ? eventColor(event) : .gdlTextSecondary)
                }
                Spacer()
                if isActive {
                    Text("AKTİF")
                        .font(.gdlCaption())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(eventColor(event).opacity(0.2))
                        .foregroundColor(eventColor(event))
                        .cornerRadius(6)
                }
            }

            Text(event.description)
                .font(.gdlBody()).foregroundColor(.gdlTextSecondary)

            Divider().background(Color.gdlDivider)

            HStack(spacing: 20) {
                modifierPill(label: "Trafik", value: event.trafficModifier)
                modifierPill(label: "Cömertlik", value: event.generosityModifier)
                modifierPill(label: "VIP", value: event.vipModifier)
            }
        }
        .padding(14)
        .gdlCard()
    }

    private func modifierPill(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
            Text(value >= 1 ? "+\(Int((value - 1) * 100))%" : "\(Int((value - 1) * 100))%")
                .font(.gdlBody())
                .foregroundColor(value >= 1 ? .gdlPositive : .gdlNegative)
        }
    }

    private func eventColor(_ event: GameEvent) -> Color {
        switch event.eventType {
        case .weddingSeason:  return .pink
        case .holiday:        return .orange
        case .touristSeason:  return .blue
        case .promotionWeek:  return .gdlPositive
        case .financeNews:    return .gdlNegative
        }
    }
}

#Preview {
    NavigationStack { EventsView().environmentObject(GameState()) }
}
