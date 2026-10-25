import Foundation

/// Chooses the next set of feelings — two of them, or up to five. Not blind
/// randomness: it favours feelings you have seen least, never puts two from
/// one family in the same set, and mostly gathers feelings of similar
/// standing, since a close call carries more information than an obvious
/// one. Roughly a third of the time it deliberately spans the
/// pleasant/unpleasant line for a clean read.
struct Pairer {
    private var recent: [String] = []

    mutating func next(given stats: Stats, count: Int) -> [Feeling] {
        let wanted = max(2, min(5, count))
        let elo = { (f: Feeling) in stats.score[f.id]?.elo ?? 1500 }
        let shown = { (f: Feeling) in stats.score[f.id]?.shown ?? 0 }

        let pool = Vocabulary.all.filter { !recent.contains($0.id) }
        let floor = pool.map(shown).min() ?? 0
        let freshest = pool.filter { shown($0) <= floor + 1 }
        let first = freshest.randomElement() ?? Vocabulary.all.randomElement()!

        var chosen = [first]
        let spanValence = Double.random(in: 0..<1) < 0.3
        let anchor = elo(first)

        while chosen.count < wanted {
            var candidates = pool.filter { f in
                !chosen.contains(f) && !chosen.contains { $0.family == f.family }
            }
            if candidates.isEmpty {
                candidates = Vocabulary.all.filter { !chosen.contains($0) }
            }
            if spanValence, chosen.count == 1 {
                let opposite = candidates.filter { ($0.valence > 0) != (first.valence > 0) }
                if !opposite.isEmpty { candidates = opposite }
            } else {
                candidates = candidates
                    .sorted { abs(elo($0) - anchor) < abs(elo($1) - anchor) }
                    .prefix(14)
                    .map { $0 }
            }
            guard let pick = candidates.randomElement() else { break }
            chosen.append(pick)
        }

        recent = (recent + chosen.map(\.id)).suffix(max(12, wanted * 3)).map { $0 }
        return chosen.shuffled()
    }

    mutating func reset() { recent = [] }
}
