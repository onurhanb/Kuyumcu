import SwiftUI

// MARK: - Color Palette

extension Color {
    static let gdlBackground    = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let gdlCard          = Color(red: 0.13, green: 0.13, blue: 0.17)
    static let gdlCardSecondary = Color(red: 0.18, green: 0.18, blue: 0.23)
    static let gdlGold          = Color(red: 0.87, green: 0.69, blue: 0.19)
    static let gdlGoldLight     = Color(red: 1.00, green: 0.85, blue: 0.40)
    static let gdlPositive      = Color(red: 0.20, green: 0.80, blue: 0.40)
    static let gdlNegative      = Color(red: 0.90, green: 0.25, blue: 0.25)
    static let gdlTextPrimary   = Color.white
    static let gdlTextSecondary = Color(white: 0.60)
    static let gdlDivider       = Color(white: 0.22)
}

// MARK: - Typography helpers

extension Font {
    static func gdlTitle()    -> Font { .system(size: 22, weight: .bold, design: .rounded) }
    static func gdlHeadline() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func gdlBody()     -> Font { .system(size: 15, weight: .regular, design: .rounded) }
    static func gdlCaption()  -> Font { .system(size: 12, weight: .regular, design: .rounded) }
    static func gdlMono()     -> Font { .system(size: 15, weight: .medium, design: .monospaced) }
}

// MARK: - View modifiers

struct GDLCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gdlCard)
            .cornerRadius(16)
    }
}

extension View {
    func gdlCard() -> some View { modifier(GDLCardModifier()) }
}
