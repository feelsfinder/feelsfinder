import SwiftUI

/// Your feelings plotted where the research puts them: pleasantness across,
/// energy up. Faint dots are the rest of the vocabulary, waiting.
struct CircumplexView: View {
    let stats: Stats
    @Binding var selected: Feeling?

    private var counts: [String: Int] {
        Dictionary(uniqueKeysWithValues: Vocabulary.all.map { ($0.id, stats.count($0.id)) })
    }

    var body: some View {
        VStack(spacing: 6) {
            Eyebrow("activated")
            HStack(spacing: 8) {
                Eyebrow("unpleasant").rotationEffect(.degrees(-90)).fixedSize().frame(width: 12)
                plot
                Eyebrow("pleasant").rotationEffect(.degrees(90)).fixedSize().frame(width: 12)
            }
            Eyebrow("quiet")
        }
    }

    private var plot: some View {
        let counts = self.counts
        let maxCount = max(1, counts.values.max() ?? 1)

        return Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            func point(_ f: Feeling) -> CGPoint {
                CGPoint(x: rect.minX + (f.valence + 1) / 2 * rect.width,
                        y: rect.maxY - f.arousal * rect.height)
            }
            func radius(_ n: Int) -> CGFloat {
                3 + sqrt(CGFloat(n) / CGFloat(maxCount)) * 8
            }

            ctx.stroke(Path(rect), with: .color(Palette.line), lineWidth: 1)
            var cross = Path()
            cross.move(to: CGPoint(x: rect.midX, y: rect.minY))
            cross.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            cross.move(to: CGPoint(x: rect.minX, y: rect.midY))
            cross.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            ctx.stroke(cross, with: .color(Palette.hair), lineWidth: 1)

            for f in Vocabulary.all where counts[f.id] == 0 {
                let p = point(f)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.8, y: p.y - 1.8, width: 3.6, height: 3.6)),
                         with: .color(Palette.ink3.opacity(0.34)))
            }

            let chosen = Vocabulary.all
                .filter { (counts[$0.id] ?? 0) > 0 }
                .sorted { (counts[$0.id] ?? 0) > (counts[$1.id] ?? 0) }

            for f in chosen.reversed() {
                let p = point(f), r = radius(counts[f.id] ?? 0)
                let box = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                // a surface ring keeps overlapping marks readable
                ctx.stroke(Path(ellipseIn: box), with: .color(Palette.surface), lineWidth: 2)
                ctx.fill(Path(ellipseIn: box),
                         with: .color(Palette.hue(forValence: f.valence).opacity(selected == nil || selected == f ? 0.85 : 0.3)))
                if selected == f {
                    ctx.stroke(Path(ellipseIn: box.insetBy(dx: -3, dy: -3)),
                               with: .color(Palette.ink), lineWidth: 1.5)
                }
            }

            // Direct labels, but only where one fits: never across another
            // disc, never across a label already placed.
            var occupied: [CGRect] = chosen.map { f in
                let p = point(f), r = radius(counts[f.id] ?? 0)
                return CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            }
            var placed = 0
            for f in chosen.prefix(8) {
                let p = point(f), r = radius(counts[f.id] ?? 0)
                let toRight = p.x < rect.maxX - 74
                let text = ctx.resolve(Text(f.name).font(.system(size: 11)).foregroundStyle(Palette.ink2))
                let size = text.measure(in: CGSize(width: 180, height: 40))
                let anchor = CGPoint(x: toRight ? p.x + r + 4 : p.x - r - 4, y: p.y)
                let box = CGRect(x: toRight ? anchor.x : anchor.x - size.width,
                                 y: anchor.y - size.height / 2,
                                 width: size.width, height: size.height).insetBy(dx: -3, dy: -2)
                if box.minX < rect.minX || box.maxX > rect.maxX { continue }
                if occupied.contains(where: { $0.intersects(box) }) { continue }
                occupied.append(box)
                ctx.draw(text, at: anchor, anchor: toRight ? .leading : .trailing)
                placed += 1
                if placed >= 5 { break }
            }
        }
        .aspectRatio(1.12, contentMode: .fit)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { plotSize = geo.size }
                    .onChange(of: geo.size) { _, new in plotSize = new }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            selected = nearest(to: location)
        }
    }

    /// Hit-test against the same placement the canvas draws with.
    /// Tapping the selected dot again clears it.
    private func nearest(to location: CGPoint) -> Feeling? {
        guard plotSize.width > 0 else { return nil }
        let rect = CGRect(origin: .zero, size: plotSize).insetBy(dx: 1, dy: 1)
        var best: (feeling: Feeling, distance: CGFloat)?
        for f in Vocabulary.all where stats.count(f.id) > 0 {
            let p = CGPoint(x: rect.minX + (f.valence + 1) / 2 * rect.width,
                            y: rect.maxY - f.arousal * rect.height)
            let d = hypot(p.x - location.x, p.y - location.y)
            if d < 26, best == nil || d < best!.distance { best = (f, d) }
        }
        guard let hit = best?.feeling else { return nil }
        return hit == selected ? nil : hit
    }

    @State private var plotSize: CGSize = .zero
}
