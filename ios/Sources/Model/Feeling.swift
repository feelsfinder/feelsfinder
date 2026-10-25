import Foundation

/// One feeling, placed on Russell's circumplex: `valence` runs
/// -1 (unpleasant) to +1 (pleasant), `arousal` 0 (quiet) to 1 (activated).
struct Feeling: Identifiable, Hashable {
    let id: String
    let name: String
    let valence: Double
    let arousal: Double
    let family: String
    let gloss: String
}

enum Vocabulary {
    static let all: [Feeling] = raw.map { r in
        Feeling(id: slug(r.0), name: r.0, valence: r.1, arousal: r.2, family: r.3, gloss: r.4)
    }

    static let byID: [String: Feeling] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func named(_ id: String) -> Feeling? { byID[id] }

    private static func slug(_ s: String) -> String {
        s.lowercased().map { $0.isLetter ? String($0) : "-" }.joined()
    }

    private static let raw: [(String, Double, Double, String, String)] = [
        ("Excited", 0.80, 0.90, "Joy", "keyed up, the good kind"),
        ("Elated", 0.90, 0.80, "Joy", "lifted clean off the ground"),
        ("Playful", 0.75, 0.65, "Joy", "up for a little mischief"),
        ("Inspired", 0.80, 0.70, "Joy", "wants to go make something"),
        ("Proud", 0.70, 0.50, "Joy", "did the thing, and it counted"),
        ("Amused", 0.65, 0.55, "Joy", "quietly laughing"),
        ("Hopeful", 0.70, 0.45, "Joy", "leaning toward the good outcome"),
        ("Energized", 0.65, 0.85, "Joy", "engine running warm"),
        ("Content", 0.70, 0.20, "Calm", "nothing missing"),
        ("Peaceful", 0.75, 0.12, "Calm", "still water"),
        ("Grateful", 0.80, 0.35, "Calm", "aware of what's here"),
        ("Relieved", 0.60, 0.30, "Calm", "the weight just left"),
        ("Rested", 0.60, 0.15, "Calm", "topped back up"),
        ("Grounded", 0.65, 0.25, "Calm", "feet on the floor"),
        ("Safe", 0.70, 0.18, "Calm", "no need to brace"),
        ("Affectionate", 0.80, 0.40, "Connection", "wants to be close"),
        ("Tender", 0.70, 0.30, "Connection", "soft toward someone"),
        ("Connected", 0.80, 0.40, "Connection", "in it with people"),
        ("Seen", 0.75, 0.35, "Connection", "someone got it right"),
        ("Lonely", -0.60, 0.40, "Connection", "no one within reach"),
        ("Left out", -0.60, 0.45, "Connection", "the room closed up"),
        ("Focused", 0.50, 0.60, "Drive", "one thing at a time"),
        ("Determined", 0.50, 0.70, "Drive", "not putting this down"),
        ("Motivated", 0.60, 0.65, "Drive", "ready to start"),
        ("Restless", -0.30, 0.70, "Drive", "can't settle anywhere"),
        ("Impatient", -0.40, 0.65, "Drive", "done with waiting"),
        ("Curious", 0.50, 0.55, "Curiosity", "wants to look closer"),
        ("Intrigued", 0.50, 0.45, "Curiosity", "something doesn't add up"),
        ("Surprised", 0.10, 0.80, "Curiosity", "didn't see it coming"),
        ("Sad", -0.70, 0.30, "Sadness", "heavy and low"),
        ("Down", -0.55, 0.25, "Sadness", "the floor dropped a little"),
        ("Disappointed", -0.60, 0.40, "Sadness", "it wasn't what you hoped"),
        ("Hurt", -0.70, 0.50, "Sadness", "something landed badly"),
        ("Wistful", -0.20, 0.28, "Sadness", "sweet, and gone"),
        ("Melancholy", -0.40, 0.22, "Sadness", "at home in the grey"),
        ("Grieving", -0.80, 0.40, "Sadness", "carrying a loss"),
        ("Numb", -0.40, 0.10, "Sadness", "the signal cut out"),
        ("Empty", -0.60, 0.15, "Sadness", "hollow where it should be"),
        ("Anxious", -0.60, 0.80, "Fear", "body ahead of the facts"),
        ("Nervous", -0.35, 0.70, "Fear", "fluttering at the edges"),
        ("Worried", -0.50, 0.60, "Fear", "running the bad branch"),
        ("Tense", -0.50, 0.70, "Fear", "holding everything tight"),
        ("Uneasy", -0.40, 0.50, "Fear", "something's off"),
        ("Dread", -0.80, 0.65, "Fear", "waiting for the drop"),
        ("Overwhelmed", -0.70, 0.85, "Fear", "too much, all at once"),
        ("Irritated", -0.45, 0.60, "Anger", "everything is grating"),
        ("Frustrated", -0.60, 0.70, "Anger", "blocked, and still pushing"),
        ("Angry", -0.70, 0.80, "Anger", "heat with a direction"),
        ("Resentful", -0.60, 0.50, "Anger", "keeping a tally"),
        ("Defensive", -0.50, 0.60, "Anger", "shields up"),
        ("Embarrassed", -0.50, 0.60, "Self-judgment", "wants to leave the room"),
        ("Guilty", -0.60, 0.45, "Self-judgment", "owes someone something"),
        ("Ashamed", -0.70, 0.50, "Self-judgment", "wrong all the way down"),
        ("Insecure", -0.60, 0.45, "Self-judgment", "not sure you measure up"),
        ("Self-critical", -0.55, 0.50, "Self-judgment", "narrating your own faults"),
        ("Tired", -0.30, 0.15, "Depletion", "running on the reserve"),
        ("Drained", -0.50, 0.12, "Depletion", "nothing left to give"),
        ("Foggy", -0.30, 0.20, "Depletion", "thinking through gauze"),
        ("Bored", -0.40, 0.20, "Depletion", "nothing to reach for"),
        ("Flat", -0.40, 0.15, "Depletion", "the colour drained out"),
        ("Burned out", -0.70, 0.18, "Depletion", "past tired, into empty"),
        ("Confused", -0.30, 0.45, "Uncertainty", "pieces won't line up"),
        ("Torn", -0.35, 0.55, "Uncertainty", "pulled both ways"),
        ("Stuck", -0.50, 0.40, "Uncertainty", "no move looks right"),
        ("Distracted", -0.20, 0.50, "Uncertainty", "attention keeps sliding"),
        ("Longing", -0.20, 0.45, "Uncertainty", "reaching for what isn't here"),
        ("Nostalgic", 0.20, 0.30, "Uncertainty", "warm toward the past")
    ]
}
