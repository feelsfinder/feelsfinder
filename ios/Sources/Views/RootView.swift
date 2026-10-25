import SwiftUI

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            CheckInView(showPatterns: { tab = 1 })
                .tabItem { Label("Check in", systemImage: "rectangle.split.1x2") }
                .tag(0)

            PatternsView()
                .tabItem { Label("Patterns", systemImage: "chart.dots.scatter") }
                .tag(1)
        }
        .background(Palette.surface)
    }
}

/// The slim bar at the top of both tabs: wordmark, and where you stand.
struct TopBar: View {
    @Environment(Store.self) private var store

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            (Text("Feels ").font(.serif(19)).italic() + Text("Finder").font(.serif(19, .medium)))
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(tally)
                .font(.label(11))
                .foregroundStyle(Palette.ink3)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.hair).frame(height: 1)
        }
    }

    private var tally: String {
        let stats = Stats(picks: store.picks)
        guard stats.choices > 0 else { return "no picks yet" }
        let picks = "\(stats.choices) pick\(stats.choices == 1 ? "" : "s")"
        return stats.streak > 0 ? "\(picks) · \(stats.streak)-day streak" : picks
    }
}
