import Foundation

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
