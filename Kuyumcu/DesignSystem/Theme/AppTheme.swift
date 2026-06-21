import SwiftUI

enum GDLSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
}

enum GDLRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 18
    static let xxl: CGFloat = 24
}

// MARK: - Color Palette

extension Color {
    static let gdlBackground    = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let gdlBackgroundTop = Color(red: 0.09, green: 0.08, blue: 0.11)
    static let gdlBackgroundBottom = Color(red: 0.03, green: 0.03, blue: 0.05)
    static let gdlCard          = Color(red: 0.13, green: 0.13, blue: 0.17)
    static let gdlCardSecondary = Color(red: 0.18, green: 0.18, blue: 0.23)
    static let gdlGold          = Color(red: 0.87, green: 0.69, blue: 0.19)
    static let gdlGoldLight     = Color(red: 1.00, green: 0.85, blue: 0.40)
    static let gdlPositive      = Color(red: 0.20, green: 0.80, blue: 0.40)
    static let gdlNegative      = Color(red: 0.90, green: 0.25, blue: 0.25)
    static let gdlTextPrimary   = Color.white
    static let gdlTextSecondary = Color(white: 0.60)
    static let gdlDivider       = Color(white: 0.22)
    static let gdlStroke        = Color.white.opacity(0.07)
    static let gdlShadow        = Color.black.opacity(0.24)
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
            .overlay(
                RoundedRectangle(cornerRadius: GDLRadius.xl)
                    .stroke(Color.gdlStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.xl))
            .shadow(color: .gdlShadow, radius: 14, x: 0, y: 6)
    }
}

extension View {
    func gdlCard() -> some View { modifier(GDLCardModifier()) }

    func gdlScreenBackground() -> some View {
        background(
            LinearGradient(
                colors: [.gdlBackgroundTop, .gdlBackground, .gdlBackgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}
