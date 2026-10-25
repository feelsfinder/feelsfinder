import Foundation
import HealthKit
import Observation

/// Writes each choice to Apple Health as a State of Mind sample, so other
/// apps can read it. Only the chosen feeling becomes a sample. The ones
/// passed over were never felt, so they ride along as metadata instead.
@Observable
final class HealthExport {
    private(set) var isOn = UserDefaults.standard.bool(forKey: "healthOn")
    private(set) var denied = false

    @ObservationIgnored private let health = HKHealthStore()

    /// State of Mind arrived in iOS 18.
    var isAvailable: Bool {
        if #available(iOS 18, *) { return HKHealthStore.isHealthDataAvailable() }
        return false
    }

    /// Asks for write access, then copies over every choice already made.
    /// Each sample carries its choice's stamp as a sync identifier, so
    /// writing one twice replaces it rather than doubling it.
    func turnOn(with picks: [Pick]) async {
        guard #available(iOS 18, *), isAvailable else { return }
        let type = HKSampleType.stateOfMindType()
        do {
            try await health.requestAuthorization(toShare: [type], read: [])
        } catch {
            return
        }
        guard health.authorizationStatus(for: type) == .sharingAuthorized else {
            await MainActor.run { denied = true }
            return
        }
        await MainActor.run {
            denied = false
            isOn = true
            UserDefaults.standard.set(true, forKey: "healthOn")
        }

        let samples = Dictionary(grouping: picks, by: \.t).compactMap { t, group in
            group.first?.winner.map { sample(at: t, win: $0, over: group.compactMap(\.loser)) }
        }
        try? await health.save(samples)
    }

    /// Stops writing. What is already in Health stays there; the person
    /// can remove it from the Health app.
    func turnOff() {
        isOn = false
        UserDefaults.standard.set(false, forKey: "healthOn")
    }

    func write(at t: Double, win: Feeling, over losers: [Feeling]) {
        guard #available(iOS 18, *), isOn else { return }
        let s = sample(at: t, win: win, over: losers)
        Task { try? await health.save(s) }
    }

    func remove(at t: Double) {
        guard #available(iOS 18, *), isOn else { return }
        let match = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeySyncIdentifier, allowedValues: [syncID(t)])
        Task { _ = try? await health.deleteObjects(of: HKSampleType.stateOfMindType(), predicate: match) }
    }

    /// Clear my data reaches into Health too, but only for samples this app wrote.
    func removeAll() {
        guard #available(iOS 18, *), isOn else { return }
        let ours = HKQuery.predicateForObjects(from: HKSource.default())
        Task { _ = try? await health.deleteObjects(of: HKSampleType.stateOfMindType(), predicate: ours) }
    }

    // MARK: samples

    private func syncID(_ t: Double) -> String { "choice-\(t)" }

    @available(iOS 18, *)
    private func sample(at t: Double, win: Feeling, over losers: [Feeling]) -> HKStateOfMind {
        HKStateOfMind(
            date: Date(timeIntervalSince1970: t / 1000),
            kind: .momentaryEmotion,
            valence: win.valence,
            labels: Self.labels[win.id].map { [$0] } ?? [],
            associations: [],
            metadata: [
                HKMetadataKeySyncIdentifier: syncID(t),
                HKMetadataKeySyncVersion: 1,
                "FeelsFinderFeeling": win.name,
                "FeelsFinderArousal": win.arousal,
                "FeelsFinderOver": losers.map(\.name).joined(separator: ", "),
            ])
    }

    /// Apple's fixed list of labels. Feelings with no honest match go
    /// unlabeled; the name is still in the metadata.
    @available(iOS 18, *)
    private static let labels: [String: HKStateOfMind.Label] = [
        "excited": .excited, "elated": .joyful, "amused": .amused, "proud": .proud,
        "hopeful": .hopeful, "content": .content, "peaceful": .peaceful,
        "grateful": .grateful, "relieved": .relieved, "lonely": .lonely,
        "surprised": .surprised, "sad": .sad, "disappointed": .disappointed,
        "anxious": .anxious, "worried": .worried, "tense": .stressed,
        "overwhelmed": .overwhelmed, "irritated": .irritated,
        "frustrated": .frustrated, "angry": .angry, "embarrassed": .embarrassed,
        "guilty": .guilty, "ashamed": .ashamed, "drained": .drained,
        "burned-out": .drained,
    ]
}
