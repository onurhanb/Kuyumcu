import Foundation

struct AppVersion: Comparable {
    let short: String
    let build: String

    static var current: AppVersion {
        let info = Bundle.main.infoDictionary
        return AppVersion(
            short: info?["CFBundleShortVersionString"] as? String ?? "1.0",
            build: info?["CFBundleVersion"] as? String ?? "1"
        )
    }

    var displayText: String {
        "\(short) B\(build)"
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compareSegments(lhs.short, rhs.short) == .orderedAscending
    }

    static func isVersion(_ version: String, below minimumVersion: String) -> Bool {
        compareSegments(version, minimumVersion) == .orderedAscending
    }

    private static func compareSegments(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0..<count {
            let lhsValue = index < lhsParts.count ? lhsParts[index] : 0
            let rhsValue = index < rhsParts.count ? rhsParts[index] : 0
            if lhsValue < rhsValue { return .orderedAscending }
            if lhsValue > rhsValue { return .orderedDescending }
        }

        return .orderedSame
    }
}
