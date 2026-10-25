import SwiftUI

/// What a round of seven picks added up to.
struct Reading: Identifiable {
    let id = UUID()
    let winners: [Feeling]

    var valence: Double { winners.isEmpty ? 0 : winners.map(\.valence).reduce(0, +) / Double(winners.count) }
    var arousal: Double { winners.isEmpty ? 0 : winners.map(\.arousal).reduce(0, +) / Double(winners.count) }

    var family: String {
        Dictionary(grouping: winners, by: \.family)
            .max { $0.value.count < $1.value.count }?.key ?? "—"
    }

    var strongest: (feeling: Feeling, times: Int)? {
        Dictionary(grouping: winners, by: \.id)
            .max { $0.value.count < $1.value.count }
            .flatMap { entry in
                Vocabulary.named(entry.key).map { ($0, entry.value.count) }
            }
    }

    var valenceWord: String {
        switch valence {
        case 0.45...:      return "clearly pleasant"
        case 0.15..<0.45:  return "leaning pleasant"
        case -0.15..<0.15: return "genuinely mixed"
        case -0.45..<(-0.15): return "leaning unpleasant"
        default:           return "clearly unpleasant"
        }
    }

    var arousalWord: String {
        switch arousal {
        case 0.62...:     return "and activated — a lot of energy in it"
        case 0.35..<0.62: return "at middling energy"
        default:          return "and quiet — low energy"
        }
    }
}

struct ReadingSheet: View {
    let reading: Reading
    let seePatterns: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Reading · \(reading.winners.count) picks · \(reading.family.lowercased())")
                .padding(.top, 22)

            Text(reading.valenceWord.prefix(1).uppercased() + reading.valenceWord.dropFirst())
                .font(.serif(28))
                .foregroundStyle(Palette.ink)
                .padding(.top, 6)

            Text("This round read as \(reading.valenceWord) \(reading.arousalWord).")
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink2)
                .padding(.top, 10)

            if let s = reading.strongest {
                Text("Strongest pull: \(s.feeling.name)\(s.times > 1 ? " — chosen \(s.times) times" : "").")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink2)
                    .padding(.top, 4)
            }

            scale.padding(.top, 22)

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Text("Keep going").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: seePatterns) {
                    Text("See patterns").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Palette.surface)
    }

    private var scale: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [Palette.negative, Palette.middle, Palette.positive],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: 6)
                    Capsule()
                        .fill(Palette.ink)
                        .frame(width: 3, height: 15)
                        .overlay(Capsule().stroke(Palette.surface, lineWidth: 2))
                        .offset(x: geo.size.width * (reading.valence + 1) / 2 - 1.5)
                }
                .frame(height: 15)
            }
            .frame(height: 15)

            HStack {
                Eyebrow("unpleasant")
                Spacer()
                Eyebrow("pleasant")
            }
        }
    }
}
