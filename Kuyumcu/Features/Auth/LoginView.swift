import SwiftUI

struct LoginView: View {
    let onAuthLogin:  () -> Void   // Google veya Apple sonrası → dükkan adı ekranı
    let onGuestLogin: () -> Void   // Misafir → direkt oyun

    @State private var showComingSoon = false

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + başlık
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gdlCard)
                            .frame(width: 100, height: 100)
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gdlGold)
                    }

                    VStack(spacing: 6) {
                        Text("Gold Dealer Life")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.gdlGold)
                        Text("Kuyumcu Simülasyonu")
                            .font(.system(size: 15))
                            .foregroundColor(.gdlTextSecondary)
                    }
                }

                Spacer()

                // Giriş butonları
                VStack(spacing: 12) {
                    // Google
                    loginButton(
                        icon: "g.circle.fill",
                        iconColor: Color(red: 0.92, green: 0.26, blue: 0.21),
                        title: "Google ile Giriş Yap",
                        style: .card
                    ) {
                        showComingSoon = true
                    }

                    // Apple
                    loginButton(
                        icon: "apple.logo",
                        iconColor: .white,
                        title: "Apple ile Giriş Yap",
                        style: .card
                    ) {
                        showComingSoon = true
                    }

                    // Ayırıcı
                    HStack {
                        Rectangle().fill(Color.gdlDivider).frame(height: 1)
                        Text("veya")
                            .font(.system(size: 12))
                            .foregroundColor(.gdlTextSecondary)
                            .padding(.horizontal, 12)
                        Rectangle().fill(Color.gdlDivider).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    // Misafir
                    loginButton(
                        icon: "person.fill",
                        iconColor: .gdlTextSecondary,
                        title: "Misafir Olarak Devam Et",
                        style: .ghost
                    ) {
                        onGuestLogin()
                    }

                    Text("Misafir girişinde ilerlemeniz kaydedilmez.")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
            }
        }
        .alert("Yakında", isPresented: $showComingSoon) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Google ve Apple ile giriş özelliği çok yakında eklenecek. Şimdilik misafir olarak devam edebilirsin.")
        }
    }

    // MARK: - Button Builder

    private enum ButtonStyle { case card, ghost }

    @ViewBuilder
    private func loginButton(icon: String, iconColor: Color, title: String, style: ButtonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(style == .card ? .gdlTextPrimary : .gdlTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(style == .card ? Color.gdlCard : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style == .ghost ? Color.gdlDivider : Color.clear, lineWidth: 1)
            )
            .cornerRadius(14)
        }
    }
}

#Preview {
    LoginView(onAuthLogin: {}, onGuestLogin: {})
}
