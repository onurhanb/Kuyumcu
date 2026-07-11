import SwiftUI

struct ShopNameView: View {
    let onComplete: (String) -> Void

    @State private var shopName  = ""
    @State private var showError = false
    @FocusState private var fieldFocused: Bool

    private let maxLength = 20

    // İzin verilen karakterler: harf (Türkçe dahil), rakam, boşluk
    private func isValid(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let allowed = CharacterSet.letters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: " "))
        return text.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private var trimmed: String { GameState.normalizedShopName(shopName) }
    private var usesPlaceholderName: Bool { GameState.isPlaceholderShopName(trimmed) }
    private var canContinue: Bool { isValid(shopName) && !usesPlaceholderName }

    var body: some View {
        ZStack {
            Color.gdlBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // İkon + başlık
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gdlCard)
                            .frame(width: 100, height: 100)
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.gdlGold)
                    }

                    VStack(spacing: 6) {
                        Text("Dükkanına İsim Ver")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.gdlTextPrimary)
                        Text("Bu isim profilinde ve sıralamada görünecek.")
                            .font(.system(size: 14))
                            .foregroundColor(.gdlTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // Giriş alanı
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Örn: Bucak Kuyumculuk", text: $shopName)
                            .font(.system(size: 17))
                            .foregroundColor(.gdlTextPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .focused($fieldFocused)
                            .onChange(of: shopName) { _, new in
                                // Karakter sınırı
                                if new.count > maxLength {
                                    shopName = String(new.prefix(maxLength))
                                }
                                showError = false
                            }

                        Spacer(minLength: 8)

                        Text("\(shopName.count)/\(maxLength)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(shopName.count >= maxLength ? .gdlNegative : .gdlTextSecondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.gdlCard)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(showError ? Color.gdlNegative : Color.gdlDivider, lineWidth: 1)
                    )

                    if showError {
                        Text(usesPlaceholderName
                             ? "\"\(GameState.placeholderShopName)\" kullanılamaz. Lütfen farklı bir dükkan adı seç."
                             : "Yalnızca harf, rakam ve boşluk kullanılabilir.")
                            .font(.system(size: 12))
                            .foregroundColor(.gdlNegative)
                    }

                    Text("Sadece harf, rakam ve boşluk  •  En fazla \(maxLength) karakter")
                        .font(.system(size: 11))
                        .foregroundColor(.gdlTextSecondary.opacity(0.6))
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 28)

                // Devam Et butonu
                Button {
                    if canContinue {
                        onComplete(trimmed)
                    } else {
                        showError = true
                    }
                } label: {
                    Text("Devam Et")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canContinue ? .black : .gdlTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canContinue ? Color.gdlGold : Color.gdlCard)
                        .cornerRadius(14)
                        .animation(.easeInOut(duration: 0.15), value: canContinue)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
            }
        }
        .onAppear { fieldFocused = true }
    }
}

#Preview {
    ShopNameView { name in print("Seçilen: \(name)") }
}
