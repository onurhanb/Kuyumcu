import Foundation
import Combine
import Supabase
import CryptoKit
import AuthenticationServices

// MARK: - Client (Credentials buraya gir)

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://jsqojglxewantwqjtadg.supabase.co")!,
    supabaseKey: "sb_publishable_HELoquuxjHzcylRRJzJvEQ_PRhQ7-TL",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
            emitLocalSessionAsInitialSession: true
        )
    )
)

// MARK: - Auth Service

@MainActor
class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var session: Session?
    @Published var isReady  = false   // İlk oturum kontrolü tamamlandı mı?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var userId: UUID? { session?.user.id }
    var userEmail: String? { session?.user.email }

    private init() {
        // Uygulama açılışında mevcut oturumu kontrol et; bitince isReady=true
        Task {
            await refreshSession()
            isReady = true
        }

        // Supabase auth olaylarını dinle
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn, .tokenRefreshed, .userUpdated:
                    self.session = session
                case .signedOut:
                    self.session = nil
                default:
                    break
                }
            }
        }
    }

    func refreshSession() async {
        do {
            session = try await supabase.auth.session
        } catch {
            session = nil
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, rawNonce: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
    }

    func deleteAccount() async throws {
        guard let token = session?.accessToken else {
            throw AuthServiceError.missingSession
        }

        supabase.functions.setAuth(token: token)
        let response: DeleteAccountResponse = try await supabase.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(method: .post, body: EmptyFunctionBody())
        )

        guard response.success else {
            throw AuthServiceError.accountDeletionFailed(response.error ?? "Bilinmeyen hata")
        }

        GameSaveService.reset()

        do {
            try await supabase.auth.signOut()
        } catch {
            // Auth kullanıcısı sunucuda silindiği için signOut hata verebilir; lokal oturumu yine kapatırız.
        }
        session = nil
    }
}

private struct EmptyFunctionBody: Encodable {}

private struct DeleteAccountResponse: Decodable {
    let success: Bool
    let error: String?
}

enum AuthServiceError: LocalizedError {
    case missingSession
    case accountDeletionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Aktif oturum bulunamadı."
        case .accountDeletionFailed(let message):
            return "Hesap silinemedi: \(message)"
        }
    }
}

// MARK: - Nonce Helpers (Apple Sign In güvenliği için)

func generateRawNonce(length: Int = 32) -> String {
    var randomBytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { charset[Int($0) % charset.count] })
}

func sha256Nonce(_ input: String) -> String {
    let data = Data(input.utf8)
    let hashed = SHA256.hash(data: data)
    return hashed.map { String(format: "%02x", $0) }.joined()
}
