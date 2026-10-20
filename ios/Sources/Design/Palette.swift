import SwiftUI

/// One token set, defined for both appearances. Blue reads as pleasant and
/// red as unpleasant everywhere in the app — the same hue does duty as the
/// accent, so the palette spends its boldness in one place.
enum Palette {
    static let ground   = dynamic(0xE9EBF0, 0x0B0D11)
    static let surface  = dynamic(0xFAFBFC, 0x14171E)
    static let raised   = dynamic(0xFFFFFF, 0x1B1F27)
    static let ink      = dynamic(0x13151B, 0xEDEFF4)
    static let ink2     = dynamic(0x4B5163, 0xA7AEBF)
    static let ink3     = dynamic(0x7B8295, 0x767D8F)
    static let line     = dynamic(0xD6DAE3, 0x2A2F3A)
    static let hair     = dynamic(0xE7EAF0, 0x21262F)
    static let accent   = dynamic(0x2558D6, 0x5286F2)
    static let positive = dynamic(0x2558D6, 0x5286F2)
    static let negative = dynamic(0xC0394B, 0xD35A6B)
    static let middle   = dynamic(0x8B90A0, 0x6C7386)
    static let wash     = dynamic(0x2558D6, 0x5286F2).opacity(0.10)

    static func hue(forValence v: Double) -> Color {
        v > 0.12 ? positive : (v < -0.12 ? negative : middle)
    }

    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red:   CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue:  CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Font {
    /// New York, the system serif — the feeling words and headings.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// SF Mono for anything numeric or labelling.
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

/// Small uppercase mono label, used as a section eyebrow throughout.
struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.label(10))
            .tracking(1.6)
            .foregroundStyle(Palette.ink3)
    }
}
