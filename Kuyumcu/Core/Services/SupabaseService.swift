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
