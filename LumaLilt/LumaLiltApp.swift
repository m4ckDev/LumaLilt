import SwiftUI

@main
struct LumaLiltApp: App {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.mint)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { phase in
                    if phase == .active { store.refreshDaily() }
                    if phase == .background { store.save() }
                }
        }
    }
}
