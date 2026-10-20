import SwiftUI
import Charts

struct PatternsView: View {
    @Environment(Store.self) private var store
    @State private var selected: Feeling?
    @State private var confirmClear = false

    private var stats: Stats { Stats(picks: store.picks) }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            ScrollView {
                let s = stats
                VStack(alignment: .leading, spacing: 30) {
                    summary(s)
                    map(s)
                    if s.total > 0 {
                        ranking(s)
                        familyMix(s)
                        trend(s)
                        recent(s)
                    } else {
                        Text("Make a few picks and this fills with a ranking, a two-week trend, and the families you spend the most time in.")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.ink3)
                    }
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 34)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .confirmationDialog("Delete every pick you have made?",
                            isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { store.clear() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: sections

    private func summary(_ s: Stats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Since you started")
            HStack(alignment: .top, spacing: 0) {
                tile("Picks", "\(s.choices)", nil)
                Rectangle().fill(Palette.hair).frame(width: 1, height: 38)
                tile("Days logged", "\(s.daysLogged)", nil)
                Rectangle().fill(Palette.hair).frame(width: 1, height: 38)
                tile("Streak", "\(s.streak)", "days")
            }
        }
    }

    private func tile(_ key: String, _ value: String, _ unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Eyebrow(key)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.serif(26)).foregroundStyle(Palette.ink).monospacedDigit()
                if let unit {
                    Text(unit).font(.system(size: 12)).foregroundStyle(Palette.ink3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 12)
        .padding(.leading, key == "Picks" ? 0 : 12)
    }

    private func map(_ s: Stats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header("Your map", "Where your feelings sit")
            Text(caption(s))
                .font(.system(size: 14))
                .foregroundStyle(Palette.ink3)
                .animation(.none, value: selected)
            CircumplexView(stats: s, selected: $selected)
                .padding(.top, 4)
        }
    }

    private func caption(_ s: Stats) -> String {
        if let f = selected {
            let n = s.count(f.id)
            return "\(f.name) — \(f.gloss). Chosen \(n)×, \(f.family.lowercased())."
        }
        return s.total > 0
            ? "Every feeling you have chosen, placed by how pleasant it is and how much energy it carries. Bigger means chosen more often — tap one."
            : "The faint dots are the whole vocabulary. Each one you choose fills in and grows."
    }

    private func ranking(_ s: Stats) -> some View {
        let hi = s.ranked.first?.score.elo ?? 1500
        let lo = s.ranked.last?.score.elo ?? 1500
        return VStack(alignment: .leading, spacing: 10) {
            header("Strongest pull", "What keeps winning")
            Text("Ranked by how often each feeling beat the feelings it was put against — not just by raw count.")
                .font(.system(size: 14))
                .foregroundStyle(Palette.ink3)
            VStack(spacing: 11) {
                ForEach(Array(s.ranked.enumerated()), id: \.element.feeling.id) { i, row in
                    BarRow(rank: "\(i + 1)",
                           name: row.feeling.name,
                           meta: "\(row.score.won)/\(row.score.shown)",
                           fraction: hi > lo ? 0.06 + (row.score.elo - lo) / (hi - lo) * 0.94 : 1)
                }
            }
            .padding(.top, 4)
        }
    }

    private func familyMix(_ s: Stats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header("Families", "Which register you live in")
            VStack(spacing: 11) {
                ForEach(s.families, id: \.name) { f in
                    BarRow(rank: "",
                           name: f.name,
                           meta: "\(Int((f.share * 100).rounded()))%",
                           fraction: f.share)
                }
            }
            .padding(.top, 4)
        }
    }

    private func trend(_ s: Stats) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -14, to: today)!
        let end = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return VStack(alignment: .leading, spacing: 10) {
            header("Two weeks", "Pleasantness, day by day")
            Text("The average pleasantness of the feelings you chose each day. Overall you sit at \(signed(s.averageValence)).")
                .font(.system(size: 14))
                .foregroundStyle(Palette.ink3)
            Chart(s.fortnight) { day in
                BarMark(x: .value("Day", day.date, unit: .day),
                        y: .value("Pleasantness", day.average),
                        width: .fixed(12))
                    .foregroundStyle(Palette.hue(forValence: day.average))
                    .cornerRadius(4)
            }
            .chartYScale(domain: -1...1)
            .chartXScale(domain: start...end)
            .chartYAxis {
                AxisMarks(position: .leading, values: [-1, 0, 1]) { value in
                    AxisGridLine().foregroundStyle(Palette.hair)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v > 0 ? "+1" : (v < 0 ? "−1" : "0"))
                                .font(.label(10))
                                .foregroundStyle(Palette.ink3)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.label(10))
                        .foregroundStyle(Palette.ink3)
                }
            }
            .frame(height: 150)
            .padding(.top, 4)
        }
    }

    private func recent(_ s: Stats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header("Recent", "Your last few calls")
            VStack(spacing: 0) {
                ForEach(s.recentChoices) { choice in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(choice.winner.name).font(.serif(17)).foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("over \(choice.losers.map(\.name).joined(separator: ", "))")
                            .font(.system(size: 14)).foregroundStyle(Palette.ink3)
                            .lineLimit(2)
                        Spacer(minLength: 6)
                        Text(choice.date, format: .relative(presentation: .numeric))
                            .font(.label(10)).foregroundStyle(Palette.ink3)
                            .fixedSize()
                    }
                    .padding(.vertical, 9)
                    if choice.id != s.recentChoices.last?.id {
                        Rectangle().fill(Palette.hair).frame(height: 1)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 18) {
            if !store.picks.isEmpty {
                ShareLink(item: store.csvFile()) {
                    Text("EXPORT CSV").font(.label(10)).tracking(1.4)
                }
                .foregroundStyle(Palette.ink3)
            }
            Button { confirmClear = true } label: {
                Text("CLEAR MY DATA").font(.label(10)).tracking(1.4)
            }
            .foregroundStyle(Palette.ink3)
            Spacer(minLength: 8)
            Text(cloudLabel)
                .font(.label(9)).tracking(0.8)
                .foregroundStyle(Palette.ink3)
                .multilineTextAlignment(.trailing)
        }
        .padding(.top, 6)
        .overlay(alignment: .top) { Rectangle().fill(Palette.hair).frame(height: 1) }
    }

    private var cloudLabel: String {
        switch store.cloud {
        case .checking:  return "ICLOUD · CHECKING"
        case .off:       return "THIS IPHONE ONLY"
        case .localOnly: return "ICLOUD UNAVAILABLE"
        case .backedUp:  return "BACKED UP TO ICLOUD"
        }
    }

    private func header(_ eyebrow: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Eyebrow(eyebrow)
            Text(title).font(.serif(22)).foregroundStyle(Palette.ink)
        }
    }

    private func signed(_ v: Double) -> String {
        String(format: "%@%.2f", v >= 0 ? "+" : "−", abs(v))
    }
}

/// One labelled magnitude bar — used for both the ranking and the family mix.
struct BarRow: View {
    let rank: String
    let name: String
    let meta: String
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(rank)
                    .font(.label(11))
                    .foregroundStyle(Palette.ink3)
                    .frame(width: 14, alignment: .leading)
                Text(name).font(.serif(17)).foregroundStyle(Palette.ink)
                Spacer()
                Text(meta).font(.label(10)).foregroundStyle(Palette.ink3).monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hair)
                    Capsule().fill(Palette.accent)
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 5)
            .padding(.leading, 24)
        }
    }
}
