import SwiftUI

struct LoginView: View {
    let onAuthLogin:  () -> Void   // Apple sonrası → dükkan adı ekranı
    let onGuestLogin: () -> Void   // Misafir → direkt oyun

    @State private var showGoogleSoon = false

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

                    // Apple — aktif
                    loginButton(
                        icon: "apple.logo",
                        iconColor: .white,
                        title: "Apple ile Giriş Yap",
                        style: .card,
                        disabled: false
                    ) {
                        onAuthLogin()
                    }

                    // Google — yakında
                    ZStack(alignment: .topTrailing) {
                        loginButton(
                            icon: "g.circle.fill",
                            iconColor: Color(red: 0.92, green: 0.26, blue: 0.21).opacity(0.4),
                            title: "Google ile Giriş Yap",
                            style: .card,
                            disabled: true
                        ) {
                            showGoogleSoon = true
                        }

                        Text("Yakında")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.gdlBackground)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.gdlTextSecondary.opacity(0.55))
                            .cornerRadius(6)
                            .offset(x: -12, y: -6)
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
                        style: .ghost,
                        disabled: false
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
        .alert("Yakında", isPresented: $showGoogleSoon) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Google ile giriş özelliği çok yakında eklenecek.")
        }
    }

    // MARK: - Button Builder

    private enum ButtonStyle { case card, ghost }

    @ViewBuilder
    private func loginButton(
        icon: String,
        iconColor: Color,
        title: String,
        style: ButtonStyle,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(
                        disabled
                            ? .gdlTextSecondary.opacity(0.4)
                            : (style == .card ? .gdlTextPrimary : .gdlTextSecondary)
                    )
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(style == .card ? Color.gdlCard.opacity(disabled ? 0.5 : 1) : Color.clear)
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
