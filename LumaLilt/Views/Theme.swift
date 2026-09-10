import SwiftUI

enum Theme {
    static let ink = Color(red: 0.035, green: 0.075, blue: 0.10)
    static let panel = Color(red: 0.075, green: 0.13, blue: 0.16)
    static let mint = Color(red: 0.65, green: 0.94, blue: 0.81)
    static func tile(_ value: Int, size: Int, palette: String, enhanced: Bool = true) -> Color {
        let color = TileAppearance.color(value, size: size, palette: palette, enhanced: enhanced)
        return Color(red: color.red, green: color.green, blue: color.blue)
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
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20).padding(.vertical, 17).frame(maxWidth: .infinity)
            .background(Theme.mint.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 18))
    }
}
