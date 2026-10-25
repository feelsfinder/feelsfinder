import Foundation

/// Where the log stands with iCloud.
enum CloudState: Equatable {
    case checking
    case off          // no iCloud account signed in on this device
    case localOnly    // iCloud is there but wouldn't take the write
    case backedUp(Date)
}

/// Backs the log up to iCloud's key-value store, and merges what other
/// devices have put there. The log is small and append-only, so it travels
/// as one compressed JSON blob under a single key — a year of heavy use
/// lands around 60 KB against a 1 MB budget.
final class CloudBackup {

    /// What actually crosses to iCloud. `removed` and `clearedAt` are what
    /// make deletions survive a merge: without them, a union would quietly
    /// resurrect every pick you took back.
    struct Snapshot: Codable {
        var picks: [Pick] = []
        var removed: [String] = []
        var clearedAt: Double = 0
    }

    private let key = "log.v1"

    /// Lazy on purpose: touching the store without the entitlement is not
    /// safe, and nothing below runs unless `isAvailable` says it may.
    private lazy var kv = NSUbiquitousKeyValueStore.default

    /// True only when the app carries the iCloud entitlement *and* the device
    /// has an iCloud account to write to.
    var isAvailable: Bool {
        #if ICLOUD_BACKUP
        return FileManager.default.ubiquityIdentityToken != nil
        #else
        return false
        #endif
    }

    func read() -> Snapshot? {
        guard let packed = kv.data(forKey: key),
              let json = try? (packed as NSData).decompressed(using: .zlib) as Data,
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: json)
        else { return nil }
        return snapshot
    }

    @discardableResult
    func write(_ snapshot: Snapshot) -> Bool {
        guard let json = try? JSONEncoder().encode(snapshot),
              let packed = try? (json as NSData).compressed(using: .zlib) as Data
        else { return false }
        kv.set(packed, forKey: key)
        return kv.synchronize()
    }

    func pull() { kv.synchronize() }

    func observe(_ handler: @escaping () -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv,
            queue: .main
        ) { _ in handler() }
    }
}
