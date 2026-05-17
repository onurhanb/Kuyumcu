import SwiftUI

struct RatesView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    // Source note
                    if let first = gameState.rates.first {
                        Text("Veriler \(first.sourceDate) tarihinde \(first.sourceName) üzerinden alınmıştır.")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }

                    // Gold rates
                    SectionCard(title: "Altın Kurları", icon: "crown.fill") {
                        let goldRates = gameState.rates.filter {
                            ["gramGold","quarterGold","halfGold","fullGold"].contains($0.type)
                        }
                        ForEach(goldRates) { rate in
                            rateDetailRow(rate: rate)
                            if rate.id != goldRates.last?.id {
                                Divider().background(Color.gdlDivider)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Currency rates
                    SectionCard(title: "Döviz Kurları", icon: "dollarsign.circle.fill") {
                        let fxRates = gameState.rates.filter { ["USD","EUR"].contains($0.type) }
                        ForEach(fxRates) { rate in
                            rateDetailRow(rate: rate)
                            if rate.id != fxRates.last?.id {
                                Divider().background(Color.gdlDivider)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Info card
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Alış / Satış Farkı", systemImage: "info.circle").foregroundColor(.gdlGold)
                            .font(.gdlHeadline())
                        Text("• Alış: Müşteriden altın/döviz aldığınızda ödediğiniz fiyat\n• Satış: Müşteriye altın/döviz sattığınızda talep ettiğiniz fiyat\n• Spread (fark) sizin temel kâr marjınızdır.")
                            .font(.gdlCaption())
                            .foregroundColor(.gdlTextSecondary)
                    }
                    .padding(14)
                    .gdlCard()
                    .padding(.horizontal)

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Güncel Kurlar")
        .navigationBarTitleDisplayMode(.large)
    }

    private func rateDetailRow(rate: Rate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rate.name)
                    .font(.gdlHeadline()).foregroundColor(.gdlTextPrimary)
            }
            Spacer()
            HStack(spacing: 20) {
                VStack(alignment: .center, spacing: 2) {
                    Text("Alış").font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                    Text(FormatUtils.tl(rate.buyPrice)).font(.gdlBody()).foregroundColor(.gdlTextPrimary)
                }
                VStack(alignment: .center, spacing: 2) {
                    Text("Satış").font(.gdlCaption()).foregroundColor(.gdlTextSecondary)
                    Text(FormatUtils.tl(rate.sellPrice)).font(.gdlBody()).foregroundColor(.gdlGold)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack { RatesView().environmentObject(GameState()) }
}
