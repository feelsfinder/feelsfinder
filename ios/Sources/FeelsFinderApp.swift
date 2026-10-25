import SwiftUI

@main
struct FeelsFinderApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Palette.accent)
        }
    }
}
