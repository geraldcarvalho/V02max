import SwiftUI

/// Big Michroma numerals. Michroma has no tabular figures (4, 7 and 9 are a little wider), so each
/// digit sits in a fixed-width cell and the timer does not jitter as it counts.
struct Numeral: View {
    let text: String
    let token: TypeToken
    var color: Color = Tokens.Colors.ink

    @ScaledMetric private var scale: CGFloat = 1

    init(_ text: String, token: TypeToken, color: Color = Tokens.Colors.ink) {
        self.text = text
        self.token = token
        self.color = color
        self._scale = ScaledMetric(wrappedValue: 1, relativeTo: token.textStyle)
    }

    var body: some View {
        // Big numerals are already at their maximum; smaller ones grow with Dynamic Type up to 1.6x.
        let size = token.size * min(scale, token.size > 40 ? 1 : 1.6)
        HStack(spacing: token.tracking * size) {
            ForEach(Array(text.enumerated()), id: \.offset) { item in
                Text(String(item.element))
                    .font(.custom(token.fontName, fixedSize: size))
                    .frame(width: item.element.isNumber ? size * Self.digitWidth : nil)
            }
        }
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(text))
    }

    /// Widest Michroma digit (the 4) is 1.0 em.
    static let digitWidth: CGFloat = 1.0

    /// "3:05" reads as "3 minutes 5 seconds" for VoiceOver.
    static func spoken(_ text: String) -> String {
        let parts = text.split(separator: ":")
        guard parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) else { return text }
        var out: [String] = []
        if m > 0 { out.append("\(m) minute" + (m == 1 ? "" : "s")) }
        if s > 0 || m == 0 { out.append("\(s) second" + (s == 1 ? "" : "s")) }
        return out.joined(separator: " ")
    }
}

/// A big numeral at the bottom left with the diagonal arrow at the bottom right.
struct NumeralRow: View {
    let text: String
    let token: TypeToken
    var color: Color = Tokens.Colors.ink
    var arrow: DiagonalArrow.Direction? = .downRight

    var body: some View {
        HStack(alignment: .bottom, spacing: Tokens.Spacing.space3) {
            Numeral(text, token: token, color: color)
            Spacer(minLength: 0)
            if let arrow {
                DiagonalArrow(direction: arrow, color: color)
            }
        }
    }
}
