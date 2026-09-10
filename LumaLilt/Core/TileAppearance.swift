import Foundation

/// Shared numeric palette definitions, testable without SwiftUI.
struct TileAppearance {
    let red: Double
    let green: Double
    let blue: Double

    static func color(_ value: Int, size: Int, palette: String, enhanced: Bool) -> TileAppearance {
        let x = Double(value % size) / Double(max(1, size - 1))
        let y = Double(value / size) / Double(max(1, size - 1))
        if enhanced {
            switch palette {
            case "Dusk": return Self(red: 0.28 + 0.66 * x, green: 0.20 + 0.66 * y, blue: 0.92 - 0.56 * x)
            case "Ember": return Self(red: 0.98 - 0.52 * y, green: 0.20 + 0.72 * x, blue: 0.16 + 0.65 * y)
            default: return Self(red: 0.12 + 0.76 * x, green: 0.28 + 0.64 * y, blue: 0.94 - 0.65 * x)
            }
        }
        switch palette {
        case "Dusk": return Self(red: 0.60 + 0.35 * x, green: 0.50 + 0.26 * y, blue: 0.86 - 0.30 * x)
        case "Ember": return Self(red: 0.97 - 0.15 * y, green: 0.49 + 0.35 * x, blue: 0.40 + 0.28 * y)
        default: return Self(red: 0.38 + 0.43 * x, green: 0.74 + 0.18 * y, blue: 0.82 - 0.23 * x)
        }
    }
}
