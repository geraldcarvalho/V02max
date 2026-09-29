import SwiftUI

/// Named sizes and derived colors used across screens. Values come from the PRD and the prototype.
enum Layout {
    static let margin = Tokens.Spacing.space4
    static let screenTop: CGFloat = 56
    static let primaryHeight: CGFloat = 72
    static let quietHeight: CGFloat = 56
    static let iconButton: CGFloat = 48
    static let stepperButton: CGFloat = 44
    static let rowMinHeight: CGFloat = 72
    static let fieldRowHeight: CGFloat = 64
    static let summaryCardRadius: CGFloat = 28
    static let sheetRadius: CGFloat = 28
    static let segmentRadius: CGFloat = 14
    static let segmentInnerRadius: CGFloat = 11
    static let arrowSize: CGFloat = 56
    static let ladderPreviewHeight: CGFloat = 84
    static let pressedScale: CGFloat = 0.98
    static let phaseTint: Double = 0.12
    static let pausedTimerOpacity: Double = 0.4
    static let phaseFade: Double = 0.25
}

extension Tokens.Colors {
    /// Dashed list dividers and chart guides.
    static let dash = ink.opacity(0.3)
    /// Text and glyphs on ink and taupe.
    static let onInk = Color.white
    /// Secondary text on the black summary card.
    static let onInkMuted = Color.white.opacity(0.7)
    static let scrim = ink.opacity(0.25)

    /// The run screen background: a 12 percent tint of the phase color over the ground.
    static func tint(_ phase: Color) -> Color {
        ground.mix(phase, amount: Layout.phaseTint)
    }
}

extension Color {
    /// Linear sRGB mix, like CSS color-mix(in srgb, …).
    func mix(_ other: Color, amount: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(amount)
        return Color(.sRGB, red: Double(r1 + (r2 - r1) * t), green: Double(g1 + (g2 - g1) * t), blue: Double(b1 + (b2 - b1) * t), opacity: Double(a1 + (a2 - a1) * t))
    }
}
