import SwiftUI
import UIKit

struct ForcedUpdateView: View {
    let config: AppUpdateConfig

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.gdlBackground,
                    Color.gdlCardSecondary.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.gdlGold.opacity(0.18))
                            .frame(width: 88, height: 88)
                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.gdlGold)
                    }

                    Text("Güncelleme Gerekli")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.gdlTextPrimary)

                    Text(config.updateMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.gdlTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 12)
                }

                VStack(spacing: 10) {
                    detailRow(label: "Yüklü Sürüm", value: AppVersion.current.displayText)
                    detailRow(label: "Minimum Sürüm", value: config.minimumSupportedVersion)
                    detailRow(label: "Son Sürüm", value: config.latestVersion)
                }
                .padding(16)
                .background(Color.gdlCard)
                .cornerRadius(16)

                Button {
                    guard let url = URL(string: config.appStoreURL) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    Text("App Store'u Aç")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gdlGold)
                        .cornerRadius(14)
                }

                Text("Devam etmek için uygulamayı güncellemen gerekiyor.")
                    .font(.system(size: 12))
                    .foregroundColor(.gdlTextSecondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gdlTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.gdlTextPrimary)
        }
    }
}

#Preview {
    ForcedUpdateView(
        config: AppUpdateConfig(
            minimumSupportedVersion: "1.3",
            latestVersion: "1.3",
            updateMessage: "Yeni güvenlik ve veri kararlılığı geliştirmeleri için uygulamayı güncelle.",
            appStoreURL: "https://apps.apple.com/app/id0000000000"
        )
    )
}
