import SwiftUI

struct OfflineView: View {
    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // İkon
                ZStack {
                    Circle()
                        .fill(Color.gdlCard)
                        .frame(width: 120, height: 120)
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 52, weight: .light))
                        .foregroundColor(.gdlGold)
                }

                // Başlık ve açıklama
                VStack(spacing: 12) {
                    Text("İnternet Bağlantısı Yok")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.gdlTextPrimary)

                    Text("Altın Dealer Life oynamak için\ninternet bağlantısı gereklidir.\nBağlantını kontrol edip tekrar dene.")
                        .font(.system(size: 15))
                        .foregroundColor(.gdlTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Alt bilgi
                Text("Bağlantı sağlandığında oyun otomatik olarak başlayacak.")
                    .font(.system(size: 12))
                    .foregroundColor(.gdlTextSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    OfflineView()
}
