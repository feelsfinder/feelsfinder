import Foundation
import Observation

/// One forced choice: `w` beat `l` at time `t` (ms since epoch, so the
/// file interchanges with the web version's export).
struct Pick: Codable, Hashable, Identifiable {
    let t: Double
    let w: String
    let l: String

    var id: String { "\(t):\(w):\(l)" }
    var date: Date { Date(timeIntervalSince1970: t / 1000) }
    var winner: Feeling? { Vocabulary.named(w) }
    var loser: Feeling? { Vocabulary.named(l) }
}

@Observable
final class Store {
    private(set) var picks: [Pick] = []
    private(set) var cloud: CloudState = .checking

    /// Tombstones. A pick you took back has to stay taken back even after a
    /// merge with a device that still remembers it.
    private var removed: Set<String> = []
    private var clearedAt: Double = 0

    private let backup = CloudBackup()
    private var observer: NSObjectProtocol?
    private var pushWork: DispatchWorkItem?

    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("picks.json")
    }()

    init() {
        load()
        connectToCloud()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// One decision. Choosing from three options records two pairwise wins —
    /// they share a timestamp, which is what groups them back into one choice.
    @discardableResult
    func record(win: Feeling, over losers: [Feeling]) -> Double {
        let t = Date().timeIntervalSince1970 * 1000
        for loser in losers where loser.id != win.id {
            picks.append(Pick(t: t, w: win.id, l: loser.id))
        }
        save()
        push()
        return t
    }

    /// Takes back one decision — every comparison it wrote shares its stamp.
    func undoChoice(at t: Double) {
        for pick in picks where pick.t == t { removed.insert(pick.id) }
        picks.removeAll { $0.t == t }
        trimTombstones()
        save()
        push()
    }

    func clear() {
        clearedAt = Date().timeIntervalSince1970 * 1000
        picks = []
        removed = []
        save()
        push()
    }

    // MARK: persistence

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        if let snapshot = try? JSONDecoder().decode(CloudBackup.Snapshot.self, from: data) {
            picks = snapshot.picks.sorted { $0.t < $1.t }
            removed = Set(snapshot.removed)
            clearedAt = snapshot.clearedAt
        } else if let legacy = try? JSONDecoder().decode([Pick].self, from: data) {
            // the format before iCloud backup existed
            picks = legacy.sorted { $0.t < $1.t }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private var snapshot: CloudBackup.Snapshot {
        CloudBackup.Snapshot(picks: picks, removed: Array(removed), clearedAt: clearedAt)
    }

    /// Keeps the tombstone list bounded — only recent take-backs can still
    /// race a slow device.
    private func trimTombstones() {
        guard removed.count > 300 else { return }
        let stamp = { (id: String) in Double(id.split(separator: ":").first ?? "0") ?? 0 }
        removed = Set(removed.sorted { stamp($0) > stamp($1) }.prefix(300))
    }

    // MARK: iCloud

    private func connectToCloud() {
        guard backup.isAvailable else { cloud = .off; return }
        observer = backup.observe { [weak self] in self?.mergeFromCloud() }
        backup.pull()
        mergeFromCloud()
    }

    /// Union of what is here and what is in iCloud, minus anything either
    /// side deleted. Picks are immutable and uniquely identified, so there
    /// is nothing to resolve — only to combine.
    private func mergeFromCloud() {
        guard backup.isAvailable else { cloud = .off; return }
        guard let remote = backup.read() else {
            push(immediately: true)
            return
        }

        clearedAt = max(clearedAt, remote.clearedAt)
        removed.formUnion(remote.removed)
        trimTombstones()

        var byID = Dictionary(picks.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for pick in remote.picks where byID[pick.id] == nil { byID[pick.id] = pick }

        let merged = byID.values
            .filter { !removed.contains($0.id) && $0.t > clearedAt }
            .sorted { $0.t < $1.t }

        let changed = merged.count != picks.count
        picks = merged
        save()

        // If iCloud is missing anything we hold, hand it back.
        if changed || remote.picks.count != merged.count {
            push(immediately: true)
        } else {
            cloud = .backedUp(Date())
        }
    }

    private func push(immediately: Bool = false) {
        pushWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.backup.isAvailable else { self.cloud = .off; return }
            self.cloud = self.backup.write(self.snapshot) ? .backedUp(Date()) : .localOnly
        }
        pushWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (immediately ? 0.1 : 1.5), execute: work)
    }

    // MARK: export

    var csv: String {
        var rows = ["timestamp,chosen,over,chosen_valence,chosen_arousal,family"]
        for p in picks {
            guard let w = p.winner, let l = p.loser else { continue }
            let stamp = ISO8601DateFormatter().string(from: p.date)
            rows.append("\(stamp),\(w.name),\(l.name),\(w.valence),\(w.arousal),\(w.family)")
        }
        return rows.joined(separator: "\n")
    }

    /// Writes the export to a temp file and hands back the URL for ShareLink.
    func csvFile() -> URL {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("feels-finder.csv")
        try? csv.data(using: .utf8)?.write(to: file, options: .atomic)
        return file
    }
}
