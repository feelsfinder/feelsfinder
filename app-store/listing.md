# Feels Finder — App Store listing

Everything below is ready to paste into App Store Connect. Character limits noted.

---

## Identity

| Field | Value |
|---|---|
| **App Name** (30) | `Feels Finder` — 12 |
| **Subtitle** (30) | `Track feelings, two at a time` — 29 |
| **Bundle ID** | `com.brianhubbell.FeelsFinder` (already registered, iCloud enabled) |
| **SKU** | `FEELSFINDER001` |
| **Primary language** | English (U.S.) |
| **Primary category** | Lifestyle |
| **Secondary category** | Health & Fitness |
| **Price** | Free (no in-app purchases) |
| **Age rating** | 4+ |
| **Copyright** | 2026 Brian Hubbell |

Primary category is deliberately **Lifestyle**, not Health & Fitness: the app makes no
health claims, and the Health category invites a stricter read of every sentence.

## URLs

| Field | Value |
|---|---|
| **Support URL** | https://feelsfinder.app |
| **Marketing URL** | same |
| **Privacy Policy URL** | https://feelsfinder.app/privacy.html |

## Keywords (100 max, commas, no spaces after commas)

```
mood,feelings,emotions,tracker,journal,check-in,wellbeing,mood log,emotion wheel,self-knowledge
```
95 characters. "Feels Finder" itself is already indexed from the app name — don't spend
keyword space on it.

## Promotional text (170, editable without a new build)

```
No scales to slide, no blank page to fill. Two feelings appear and you pick the closer
one. A few taps a week, and the shape of your own weather starts showing up.
```

## Description (4000 max)

```
Most mood trackers ask you to be your own instrument. Rate today, 1 to 10. Describe
how you feel in your own words. If you have ever stared at that blank box and closed
the app, Feels Finder asks something easier.

Two feelings appear. You pick the one closer to right now. That's it.

Do that a few times a week and the small choices add up to something a rating never
gives you: a picture of your own weather, built from moments you actually answered
honestly.

A FORCED CHOICE IS EASIER TO ANSWER
Every pick is a comparison, so the app can rank feelings the way a tournament ranks
players. Beating "content" counts for more than beating "bored". Over time the
feelings that keep winning rise to the top, whether or not you would have thought to
name them.

PAIRS THAT ARE WORTH ANSWERING
The choices aren't random. Feels Finder favours feelings you have seen least, never
puts two from the same family against each other, and mostly matches feelings of
similar standing, because a close call tells you more than an obvious one. Every
feeling comes with a short gloss, so near-synonyms stay distinguishable: wistful is
"sweet, and gone", melancholy is "at home in the grey".

WHAT YOU GET BACK
• Your map — every feeling you have chosen, plotted by how pleasant it is and how
  much energy it carries. Tap any dot to name it.
• What keeps winning — a running ranking across your whole history.
• Which register you live in — your picks grouped into families, from Joy and Calm
  to Depletion and Uncertainty.
• Two weeks at a glance — the average pleasantness of each day, charted.
• A reading every seven picks — how pleasant, how activated, what pulled hardest.

BUILT FOR ACTUALLY USING
• Two choices, or up to five, whichever you're in the mood for.
• Swipe forward to pass on a set that doesn't fit.
• Swipe back to undo — the answer is taken back, not just hidden.
• 67 feelings across 11 families.

YOURS, AND ONLY YOURS
No account. No sign-up. No servers, no analytics, no ads, no third-party SDKs. Your
picks live on your iPhone and, if you use iCloud, in your own private iCloud storage
where only your devices can read them. Nothing reaches the developer, because there
is nowhere for it to go. Export everything as a CSV whenever you like, and delete
everything from inside the app.

Feels Finder is a record of what you noticed. It isn't therapy, it doesn't diagnose
anything, and it won't tell you what to do about any of it.
```

## What's New (version 1.0)

```
First release.
```

## App Privacy (Data Collection section)

Answer: **Data Not Collected.**

That answer is accurate and defensible: the app has no networking code beyond
NSUbiquitousKeyValueStore, which writes to the user's own iCloud under their Apple
Account. Data the developer never receives is not collected data.

- Tracking: **No**
- Third-party advertising: **No**
- Analytics: **No**

## Export compliance

`ITSAppUsesNonExemptEncryption = NO` is set in Info.plist, so the upload won't ask.
Accurate: the only compression is zlib, and there is no cryptography.

## App Review notes

```
Feels Finder needs no account, login, or demo credentials — open it and it works.

The app presents two (or up to five) feelings and records which one the user picks.
All data is stored locally in the app container and, when iCloud is available, in the
user's own NSUbiquitousKeyValueStore. There is no server, no analytics, and no
third-party SDK. The app makes no medical, diagnostic, or therapeutic claims.

To see the aggregate views on a fresh install, make several picks on the Check in
tab, then open the Patterns tab.
```

## Screenshots

`app-store/screenshots/` — 1320 × 2868 (iPhone 6.9", the only size App Store Connect
now requires; there is no iPad build, so no iPad set is needed).

1. `1-checkin-pair.png` — the core interaction, two discs
2. `2-checkin-four.png` — the same screen set to four choices
3. `3-patterns.png` — the map, stats, and ranking

Suggested caption overlays, if you add them later: "Pick the closer one." /
"Two choices, or five." / "Watch the map fill in."
