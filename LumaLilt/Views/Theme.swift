import SwiftUI

enum Theme {
    static let ink = Color(red: 0.035, green: 0.075, blue: 0.10)
    static let panel = Color(red: 0.075, green: 0.13, blue: 0.16)
    static let mint = Color(red: 0.65, green: 0.94, blue: 0.81)
    static func tile(_ value: Int, size: Int, palette: String) -> Color {
        let x = Double(value % size) / Double(size - 1)
        let y = Double(value / size) / Double(size - 1)
        switch palette {
        case "Dusk": return Color(red: 0.60 + 0.35 * x, green: 0.50 + 0.26 * y, blue: 0.86 - 0.30 * x)
        case "Ember": return Color(red: 0.97 - 0.15 * y, green: 0.49 + 0.35 * x, blue: 0.40 + 0.28 * y)
        default: return Color(red: 0.38 + 0.43 * x, green: 0.74 + 0.18 * y, blue: 0.82 - 0.23 * x)
        }
    }
}

struct Panel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(Theme.ink)
            .padding(.vertical, 17).frame(maxWidth: .infinity)
            .background(Theme.mint.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 18))
    }
}
