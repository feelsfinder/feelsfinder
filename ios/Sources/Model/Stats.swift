import Foundation

/// Everything the Patterns tab shows, derived by replaying the whole log.
/// Nothing is stored but the picks themselves.
struct Stats {
    struct Score {
        var elo: Double = 1500
        var won: Int = 0
        var shown: Int = 0
    }

    /// One decision: what won, and what it was up against.
    struct Choice: Identifiable {
        let winner: Feeling
        let losers: [Feeling]
        let date: Date
        var id: Double { date.timeIntervalSince1970 }
    }

    struct DayPoint: Identifiable {
        let date: Date
        let average: Double
        let count: Int
        var id: Date { date }
    }

    private(set) var score: [String: Score] = [:]
    private(set) var total: Int = 0
    private(set) var choices: Int = 0
    private(set) var daysLogged: Int = 0
    private(set) var streak: Int = 0
    private(set) var averageValence: Double = 0
    private(set) var families: [(name: String, share: Double)] = []
    private(set) var ranked: [(feeling: Feeling, score: Score)] = []
    private(set) var recentChoices: [Choice] = []
    private(set) var fortnight: [DayPoint] = []

    static let k = 26.0

    init(picks: [Pick]) {
        for f in Vocabulary.all { score[f.id] = Score() }
        total = picks.count

        var valenceSum = 0.0
        var familyCount: [String: Int] = [:]
        var byDay: [Date: [Double]] = [:]
        var counted = Set<Double>()
        let cal = Calendar.current

        for p in picks {
            guard let w = p.winner, let l = p.loser,
                  var ws = score[p.w], var ls = score[p.l] else { continue }

            // Pairwise choices imply a ranking: Elo, replayed in order.
            let expected = 1 / (1 + pow(10, (ls.elo - ws.elo) / 400))
            ws.elo += Stats.k * (1 - expected)
            ls.elo -= Stats.k * (1 - expected)
            ws.won += 1; ws.shown += 1; ls.shown += 1
            score[p.w] = ws; score[p.l] = ls

            // A four-way choice is three comparisons but one feeling — count it once.
            if counted.insert(p.t).inserted {
                valenceSum += w.valence
                familyCount[w.family, default: 0] += 1
                byDay[cal.startOfDay(for: p.date), default: []].append(w.valence)
            }
            _ = l
        }

        choices = counted.count
        averageValence = counted.isEmpty ? 0 : valenceSum / Double(counted.count)
        daysLogged = byDay.count

        let grouped = Dictionary(grouping: picks, by: \.t)
        recentChoices = grouped.keys.sorted(by: >).prefix(8).compactMap { t in
            guard let group = grouped[t], let winner = group.first?.winner else { return nil }
            return Choice(winner: winner,
                          losers: group.compactMap(\.loser),
                          date: Date(timeIntervalSince1970: t / 1000))
        }

        families = familyCount
            .map { (name: $0.key, share: Double($0.value) / Double(max(1, counted.count))) }
            .sorted { $0.share > $1.share }
            .prefix(5)
            .map { $0 }

        ranked = Vocabulary.all
            .compactMap { f in score[f.id].map { (feeling: f, score: $0) } }
            .filter { $0.score.shown >= 2 }
            .sorted { $0.score.elo > $1.score.elo }
            .prefix(8)
            .map { $0 }

        // Streak: consecutive days back from today (or yesterday, if today is untouched).
        var cursor = cal.startOfDay(for: Date())
        if byDay[cursor] == nil { cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
        var run = 0
        while byDay[cursor] != nil {
            run += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        streak = run

        let today = cal.startOfDay(for: Date())
        fortnight = (0..<14).reversed().compactMap { back in
            guard let day = cal.date(byAdding: .day, value: -back, to: today),
                  let values = byDay[day], !values.isEmpty else { return nil }
            return DayPoint(date: day,
                            average: values.reduce(0, +) / Double(values.count),
                            count: values.count)
        }
    }

    func count(_ id: String) -> Int { score[id]?.won ?? 0 }
}
