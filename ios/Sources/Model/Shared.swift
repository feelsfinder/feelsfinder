import Foundation

/// Files and settings the app and the widget both reach, in the App Group.
enum Shared {
    static let group = "group.com.brianhubbell.FeelsFinder"
    static let defaults = UserDefaults(suiteName: group) ?? .standard

    static func file(_ name: String) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent(name)
    }
}

/// The app's log, copied where the widget can read it.
enum SharedLog {
    static var url: URL? { Shared.file("picks.json") }

    static func read() -> [Pick] {
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Pick].self, from: data)) ?? []
    }
}

/// Picks made from the widget, waiting for the app. The widget can't reach
/// the app's store, iCloud or Health, so it leaves them here and the app
/// takes them in the next time it comes forward. Both sides go through a
/// file coordinator so a pick can't land while the app is emptying it.
enum Inbox {
    static var url: URL? { Shared.file("inbox.json") }

    static func read() -> [Pick] {
        guard let url, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Pick].self, from: data)) ?? []
    }

    static func append(_ picks: [Pick]) {
        update { $0 + picks }
    }

    /// Hands back everything waiting and leaves the inbox empty.
    static func take() -> [Pick] {
        var taken: [Pick] = []
        update { waiting in taken = waiting; return [] }
        return taken
    }

    private static func update(_ change: ([Pick]) -> [Pick]) {
        guard let url else { return }
        var error: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forMerging, error: &error) { url in
            let current = (try? Data(contentsOf: url))
                .flatMap { try? JSONDecoder().decode([Pick].self, from: $0) } ?? []
            if let data = try? JSONEncoder().encode(change(current)) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
