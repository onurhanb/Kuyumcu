import Foundation

enum FormatUtils {

    private static let tlFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle          = .decimal
        f.groupingSeparator    = "."
        f.decimalSeparator     = ","
        f.maximumFractionDigits = 0
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle          = .decimal
        f.groupingSeparator    = "."
        f.decimalSeparator     = ","
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// Formats a TL amount: ₺250.000
    static func tl(_ value: Double) -> String {
        let str = tlFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "₺\(str)"
    }

    /// Formats with 2 decimal places: 4.580,00
    static func decimal(_ value: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "0,00"
    }

    /// Compact format for large numbers: 1,2M, 450K
    static func compact(_ value: Double) -> String {
        switch abs(value) {
        case 1_000_000_000...: return String(format: "%.1fB", value / 1_000_000_000)
        case 1_000_000...:     return String(format: "%.1fM", value / 1_000_000)
        case 1_000...:         return String(format: "%.0fK", value / 1_000)
        default:               return String(format: "%.0f", value)
        }
    }

    /// Compact TL: ₺1,2M
    static func tlCompact(_ value: Double) -> String {
        "₺\(compact(value))"
    }

    private static let wholeFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle           = .decimal
        f.groupingSeparator     = "."
        f.decimalSeparator      = ","
        f.maximumFractionDigits = 0
        return f
    }()

    /// Whole number with thousand separators, no decimals: 10.000
    static func wholeNumber(_ value: Double) -> String {
        wholeFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
