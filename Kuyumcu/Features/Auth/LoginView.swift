import SwiftUI
import AuthenticationServices

struct LoginView: View {
    let onAuthLogin: () -> Void   // Başarılı giriş → oyun

    @State private var isSigningIn         = false
    @State private var errorMessage: String?
    @State private var coordinator: AppleSignInCoordinator?

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
                        title: isSigningIn ? "Giriş yapılıyor..." : "Apple ile Giriş Yap",
                        style: .card,
                        disabled: isSigningIn
                    ) {
                        startAppleSignIn()
                    }

                    // Hata mesajı
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.gdlNegative)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    Text("Giriş yaparak ilerlemeniz buluta kaydedilir.")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Apple Sign In

    private func startAppleSignIn() {
        isSigningIn  = true
        errorMessage = nil

        let rawNonce    = generateRawNonce()
        let hashedNonce = sha256Nonce(rawNonce)

        let c = AppleSignInCoordinator()
        c.rawNonce = rawNonce
        c.onSuccess = { idToken, nonce in
            Task {
                do {
                    try await AuthService.shared.signInWithApple(idToken: idToken, rawNonce: nonce)
                    await MainActor.run {
                        isSigningIn = false
                        onAuthLogin()
                    }
                } catch {
                    await MainActor.run {
                        isSigningIn  = false
                        errorMessage = "Giriş başarısız: \(error.localizedDescription)"
                    }
                }
            }
        }
        c.onError = { error in
            DispatchQueue.main.async {
                isSigningIn  = false
                // ASAuthorizationError.canceled → kullanıcı iptal etti, mesaj gösterme
                let asError = error as? ASAuthorizationError
                if asError?.code != .canceled {
                    errorMessage = "Apple ile giriş başarısız oldu."
                }
            }
        }
        coordinator = c

        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate                    = c
        controller.presentationContextProvider = c
        controller.performRequests()
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
                if disabled && icon == "apple.logo" {
                    ProgressView().tint(.gdlGold).scaleEffect(0.8)
                }
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
        .disabled(disabled)
    }
}

// MARK: - Apple Sign In Coordinator

class AppleSignInCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    var rawNonce: String = ""
    var onSuccess: ((String, String) -> Void)?
    var onError:   ((Error) -> Void)?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData  = credential.identityToken,
            let idToken    = String(data: tokenData, encoding: .utf8)
        else {
            onError?(NSError(domain: "AppleSignIn", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Token alınamadı"]))
            return
        }
        onSuccess?(idToken, rawNonce)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        onError?(error)
    }
}

#Preview {
    LoginView(onAuthLogin: {})
}
