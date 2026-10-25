import SwiftUI

@main
struct FeelsFinderApp: App {
    @State private var store = Store()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Palette.accent)
                .onChange(of: phase) { _, now in
                    if now == .active { store.takeFromWidget() }
                }
        }
    }
}
