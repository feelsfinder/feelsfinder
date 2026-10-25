import SwiftUI
import UIKit

/// The choices sit as a cluster of discs on a card. Tap one to answer; swipe
/// the card forward (left) to pass on the set, or back (right) to return to
/// the last one — which also takes back the answer you gave it. How many
/// discs appear is up to you: the stepper spells the set out, A,B through
/// A,B,C,D,E.
struct CheckInView: View {
    let showPatterns: () -> Void

    @Environment(Store.self) private var store
    @AppStorage("choiceCount") private var choiceCount: Int = 2

    @State private var pairer = Pairer()
    @State private var options: [Feeling] = []
    @State private var history: [Dealt] = []
    @State private var drag: CGFloat = 0
    @State private var arenaWidth: CGFloat = 400
    @State private var pressed: String?
    @State private var settling = false
    @State private var sessionWinners: [Feeling] = []
    @State private var reading: Reading?

    private let choiceHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let lightHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let letters = ["A", "B", "C", "D", "E"]

    /// A card that has already left the deck, kept so it can come back.
    struct Dealt {
        let options: [Feeling]
        let recordedAt: Double?
        let winner: Feeling?
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            promptRow
            cluster
            passBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .onAppear {
            choiceHaptic.prepare()
            lightHaptic.prepare()
            if options.isEmpty { deal() }
        }
        .onChange(of: choiceCount) { _, _ in
            withAnimation(.easeOut(duration: 0.26)) { deal() }
        }
        .sheet(item: $reading) { r in
            ReadingSheet(reading: r, seePatterns: {
                reading = nil
                showPatterns()
            })
            .presentationDetents([.height(390)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: prompt and stepper

    private var promptRow: some View {
        HStack(spacing: 12) {
            Text(choiceCount == 2 ? "Right now — which one is closer?"
                                  : "Right now — which one is closest?")
                .font(.serif(16))
                .foregroundStyle(Palette.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            stepper
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }

    private var stepper: some View {
        HStack(spacing: 4) {
            stepButton("minus", enabled: choiceCount > 2) { set(choiceCount - 1) }
            Text(letters.prefix(choiceCount).joined(separator: ","))
                .font(.label(11))
                .foregroundStyle(Palette.ink2)
                .frame(minWidth: 30)
                .contentTransition(.identity)
            stepButton("plus", enabled: choiceCount < 5) { set(choiceCount + 1) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(Palette.ground))
        .overlay(Capsule().strokeBorder(Palette.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Number of choices: \(choiceCount)")
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(enabled ? Palette.ink2 : Palette.ink3.opacity(0.35))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func set(_ n: Int) {
        let clamped = max(2, min(5, n))
        guard clamped != choiceCount else { return }
        lightHaptic.impactOccurred(intensity: 0.6)
        choiceCount = clamped
    }

    // MARK: the cluster

    private var cluster: some View {
        GeometryReader { geo in
            let plan = layout(in: geo.size, count: options.count)
            ZStack {
                edgeHints

                ZStack {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, feeling in
                        disc(feeling, diameter: plan.diameter)
                            .position(plan.centres[min(index, plan.centres.count - 1)])
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: drag)
                .rotationEffect(.degrees(max(-5, min(5, drag / 26))))
                .opacity(1 - min(0.4, abs(drag) / 760))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(cardDrag)
            .onAppear { arenaWidth = geo.size.width }
            .onChange(of: geo.size.width) { _, new in arenaWidth = new }
        }
    }

    /// Only visible while you are dragging — they name what letting go does.
    private var edgeHints: some View {
        HStack {
            hint("arrow.uturn.backward", "BACK")
                .opacity(history.isEmpty ? 0 : min(1, max(0, drag / 72)))
            Spacer()
            hint("arrow.turn.up.right", "SKIP")
                .opacity(min(1, max(0, -drag / 72)))
        }
        .padding(.horizontal, 14)
    }

    private func hint(_ symbol: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 15))
            Text(label).font(.label(9)).tracking(1.6)
        }
        .foregroundStyle(Palette.accent)
    }

    private var cardDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !settling else { return }
                let dx = value.translation.width
                // going back needs somewhere to go back to; otherwise it resists
                drag = (dx > 0 && history.isEmpty) ? dx * 0.22 : dx
            }
            .onEnded { value in
                guard !settling else { return }
                let dx = value.translation.width
                if dx < -72 {
                    pass()
                } else if dx > 72, !history.isEmpty {
                    goBack()
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { drag = 0 }
                }
            }
    }

    private func disc(_ f: Feeling, diameter: CGFloat) -> some View {
        let isPressed = pressed == f.id
        return Button {
            choose(f)
        } label: {
            VStack(spacing: 5) {
                Text(f.name)
                    .font(.serif(nameSize(diameter)))
                    .foregroundStyle(isPressed ? Palette.accent : Palette.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.45)
                    .lineLimit(3)
                if diameter >= 132 {
                    Text(f.gloss)
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.ink3)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, diameter * 0.13)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(isPressed ? Palette.wash : Palette.raised))
            .overlay(Circle().strokeBorder(isPressed ? Palette.accent : Palette.line, lineWidth: 1))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func nameSize(_ diameter: CGFloat) -> CGFloat {
        switch diameter {
        case 168...: return 25
        case 144..<168: return 22
        case 126..<144: return 19
        default: return 17
        }
    }

    /// Rows of discs, gently staggered so the set reads as a cluster
    /// rather than a grid.
    private func layout(in size: CGSize, count: Int) -> (diameter: CGFloat, centres: [CGPoint]) {
        guard count > 0 else { return (0, []) }
        let rows: [Int]
        switch count {
        case 2: rows = [2]
        case 3: rows = [2, 1]
        case 4: rows = [2, 2]
        default: rows = [2, 2, 1]
        }
        let widest = CGFloat(rows.max() ?? 1)
        let gap: CGFloat = 26
        let byWidth = (size.width - 36 - gap * (widest - 1)) / widest
        let byHeight = (size.height - 28 - gap * CGFloat(rows.count - 1)) / CGFloat(rows.count)
        let d = max(96, min(byWidth, byHeight, 188))

        let blockHeight = d * CGFloat(rows.count) + gap * CGFloat(rows.count - 1)
        var y = (size.height - blockHeight) / 2 + d / 2
        var centres: [CGPoint] = []

        for (r, n) in rows.enumerated() {
            let rowWidth = d * CGFloat(n) + gap * CGFloat(n - 1)
            let shift: CGFloat = rows.count > 1 ? (r % 2 == 0 ? -15 : 15) : 0
            var x = (size.width - rowWidth) / 2 + d / 2 + shift
            for i in 0..<n {
                let lift: CGFloat = n > 1 ? (i % 2 == 0 ? -10 : 10) : 0
                centres.append(CGPoint(x: x, y: y + lift))
                x += d + gap
            }
            y += d + gap
        }
        return (d, centres)
    }

    // MARK: pass

    private var passBar: some View {
        Button {
            pass()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.turn.up.right").font(.system(size: 13))
                Text(choiceCount == 2 ? "NEITHER" : "NONE OF THESE")
                    .font(.label(11)).tracking(1.6)
            }
            .foregroundStyle(Palette.ink3)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Palette.ground)
            .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: actions

    private func deal() {
        options = pairer.next(given: Stats(picks: store.picks), count: choiceCount)
    }

    /// Slides the card out one way and the next one in from the other.
    private func wipe(towards direction: CGFloat, change: @escaping () -> Void) {
        let distance = arenaWidth + 80
        settling = true
        withAnimation(.easeIn(duration: 0.17)) { drag = direction * distance }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            change()
            drag = -direction * distance
            withAnimation(.easeOut(duration: 0.24)) { drag = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { settling = false }
        }
    }

    private func pass() {
        guard !settling, !options.isEmpty else { return }
        lightHaptic.impactOccurred(intensity: 0.7)
        let leaving = Dealt(options: options, recordedAt: nil, winner: nil)
        wipe(towards: -1) {
            remember(leaving)
            deal()
        }
    }

    private func goBack() {
        guard !settling, let previous = history.last else { return }
        lightHaptic.impactOccurred(intensity: 0.7)
        history.removeLast()
        if let stamp = previous.recordedAt {
            store.undoChoice(at: stamp)
            if let winner = previous.winner, sessionWinners.last?.id == winner.id {
                sessionWinners.removeLast()
            }
        }
        wipe(towards: 1) { options = previous.options }
    }

    private func remember(_ card: Dealt) {
        history.append(card)
        if history.count > 20 { history.removeFirst(history.count - 20) }
    }

    private func choose(_ f: Feeling) {
        guard !settling else { return }
        settling = true
        choiceHaptic.impactOccurred()
        withAnimation(.easeOut(duration: 0.15)) { pressed = f.id }

        let stamp = store.record(win: f, over: options.filter { $0.id != f.id })
        sessionWinners.append(f)
        let leaving = Dealt(options: options, recordedAt: stamp, winner: f)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            pressed = nil
            settling = false
            wipe(towards: -1) {
                remember(leaving)
                deal()
            }
            if sessionWinners.count % 7 == 0 {
                reading = Reading(winners: Array(sessionWinners.suffix(7)))
            }
        }
    }
}
