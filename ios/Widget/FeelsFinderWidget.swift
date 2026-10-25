import AppIntents
import SwiftUI
import WidgetKit

@main
struct FeelsFinderWidgets: WidgetBundle {
    var body: some Widget {
        CheckInWidget()
    }
}

/// The check-in, on the home screen. Tap a disc to answer and the next set
/// is dealt in place; the app takes the pick in when it next opens.
struct CheckInWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "checkin", provider: Provider()) { entry in
            CheckInWidgetView(entry: entry)
                .containerBackground(Palette.surface, for: .widget)
        }
        .configurationDisplayName("Check in")
        .description("Pick the feeling closest to right now, without opening the app.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: the deck

/// What the widget is showing, kept in the App Group between taps.
enum Deck {
    private static var defaults: UserDefaults { Shared.defaults }

    static var count: Int {
        let n = defaults.integer(forKey: "choiceCount")
        return n == 0 ? 2 : max(2, min(5, n))
    }

    static var options: [Feeling] {
        (defaults.stringArray(forKey: "widgetOptions") ?? []).compactMap(Vocabulary.named)
    }

    static var last: (name: String, date: Date)? {
        guard let name = defaults.string(forKey: "widgetLastName") else { return nil }
        let t = defaults.double(forKey: "widgetLastTime")
        return (name, Date(timeIntervalSince1970: t / 1000))
    }

    /// The current set, dealing one if there is none or the count changed.
    static func current() -> [Feeling] {
        let shown = options
        return shown.count == count ? shown : deal()
    }

    @discardableResult
    static func deal() -> [Feeling] {
        var pairer = Pairer(recent: defaults.stringArray(forKey: "widgetRecent") ?? [])
        let next = pairer.next(given: Stats(picks: SharedLog.read() + Inbox.read()), count: count)
        defaults.set(next.map(\.id), forKey: "widgetOptions")
        defaults.set(pairer.recent, forKey: "widgetRecent")
        return next
    }

    static func choose(_ id: String) {
        let shown = options
        guard let win = shown.first(where: { $0.id == id }) else { return }
        let t = Date().timeIntervalSince1970 * 1000
        Inbox.append(shown.filter { $0.id != id }.map { Pick(t: t, w: win.id, l: $0.id) })
        defaults.set(win.name, forKey: "widgetLastName")
        defaults.set(t, forKey: "widgetLastTime")
        deal()
    }
}

struct ChooseFeeling: AppIntent {
    static var title: LocalizedStringResource = "Choose a feeling"
    static var isDiscoverable = false

    @Parameter(title: "Feeling") var feeling: String

    init() {}
    init(_ feeling: Feeling) { self.feeling = feeling.id }

    func perform() async throws -> some IntentResult {
        Deck.choose(feeling)
        return .result()
    }
}

struct SkipSet: AppIntent {
    static var title: LocalizedStringResource = "Skip this set"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        Deck.deal()
        return .result()
    }
}

// MARK: timeline

struct Entry: TimelineEntry {
    let date: Date
    let options: [Feeling]
    let last: (name: String, date: Date)?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, options: Array(Vocabulary.all.prefix(2)), last: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, options: Deck.current(), last: Deck.last))
    }

    /// Taps reload the widget themselves. Otherwise a fresh set every few
    /// hours, so it isn't the same question all afternoon.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = Entry(date: .now, options: Deck.current(), last: Deck.last)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3 * 3600))))
    }
}

// MARK: view

struct CheckInWidgetView: View {
    let entry: Entry

    var body: some View {
        VStack(spacing: 10) {
            Text(entry.options.count == 2 ? "Right now, which one is closer?"
                                          : "Right now, which one is closest?")
                .font(.serif(16))
                .foregroundStyle(Palette.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { geo in
                cluster(in: geo.size)
            }
            footer
        }
    }

    /// Two discs side by side; more go in two rows, the longer one on top.
    private func cluster(in size: CGSize) -> some View {
        let options = entry.options
        let rows = options.count <= 2 ? [options] : [Array(options.prefix((options.count + 1) / 2)),
                                                     Array(options.dropFirst((options.count + 1) / 2))]
        let gap: CGFloat = 10
        let across = CGFloat(rows.map(\.count).max() ?? 1)
        let diameter = min((size.width - gap * (across - 1)) / across,
                           (size.height - gap * CGFloat(rows.count - 1)) / CGFloat(rows.count))
        return VStack(spacing: gap) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: gap) {
                    ForEach(row) { disc($0, diameter: diameter) }
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func disc(_ f: Feeling, diameter: CGFloat) -> some View {
        Button(intent: ChooseFeeling(f)) {
            VStack(spacing: 4) {
                Text(f.name)
                    .font(.serif(diameter >= 150 ? 22 : 18))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                if diameter >= 120 {
                    Text(f.gloss)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.ink3)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, diameter * 0.13)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(Palette.raised))
            .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            if let last = entry.last {
                (Text(last.name).font(.serif(14)).foregroundStyle(Palette.ink2)
                 + Text("  ") + Text(last.date, style: .relative).font(.label(10)).foregroundStyle(Palette.ink3))
                    .lineLimit(1)
            }
            Spacer()
            Button(intent: SkipSet()) {
                Text("SKIP").font(.label(10)).tracking(1.4).foregroundStyle(Palette.ink3)
                    .padding(.vertical, 4).padding(.leading, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
