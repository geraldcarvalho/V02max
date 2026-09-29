import SwiftUI

/// A text style from the design system. Sizes scale with Dynamic Type relative to `textStyle`.
struct TypeToken {
    let fontName: String
    let size: CGFloat
    let lineHeight: CGFloat
    /// Letter spacing in em.
    let tracking: CGFloat
    var textStyle: Font.TextStyle = .body

    init(fontName: String, size: CGFloat, lineHeight: CGFloat, tracking: CGFloat, textStyle: Font.TextStyle = .body) {
        self.fontName = fontName
        self.size = size
        self.lineHeight = lineHeight
        self.tracking = tracking
        self.textStyle = textStyle
    }

    var font: Font { .custom(fontName, size: size, relativeTo: textStyle) }

    func sized(_ newSize: CGFloat) -> TypeToken {
        TypeToken(fontName: fontName, size: newSize, lineHeight: newSize * lineHeight / size, tracking: tracking, textStyle: textStyle)
    }

    func font(_ name: String) -> TypeToken {
        TypeToken(fontName: name, size: size, lineHeight: lineHeight, tracking: tracking, textStyle: textStyle)
    }

    func relative(to style: Font.TextStyle) -> TypeToken {
        TypeToken(fontName: fontName, size: size, lineHeight: lineHeight, tracking: tracking, textStyle: style)
    }
}

/// Styles derived from the tokens for places the token set does not name directly.
extension TypeToken {
    static let display = Tokens.Typography.title.relative(to: .title2)
    static let phase = Tokens.Typography.phase.relative(to: .headline)
    static let label = Tokens.Typography.label.relative(to: .caption2)
    static let body = Tokens.Typography.body
    static let bodyMedium = Tokens.Typography.body.font("HankenGrotesk-Medium")
    static let bodySemibold = Tokens.Typography.body.font("HankenGrotesk-SemiBold")
    static let small = Tokens.Typography.body.sized(15).font("HankenGrotesk-Regular").relative(to: .subheadline)
    static let smallSemibold = Tokens.Typography.body.sized(15).font("HankenGrotesk-SemiBold").relative(to: .subheadline)
    static let button = Tokens.Typography.button.relative(to: .title3)
    static let quietButton = Tokens.Typography.body.font("HankenGrotesk-Medium")
    static let weekday = Tokens.Typography.numeralSm.relative(to: .subheadline)
    static let value = Tokens.Typography.numeralMd.sized(22).relative(to: .title3)
    static let stat = Tokens.Typography.numeralMd.relative(to: .title2)
    static let percent = Tokens.Typography.numeralMd.relative(to: .title2)
    static let runTimer = Tokens.Typography.numeralXl.relative(to: .largeTitle)
    static let runTimerLong = Tokens.Typography.numeralLg.relative(to: .largeTitle)
    static let countdown = Tokens.Typography.numeralXl.sized(160).relative(to: .largeTitle)
    static let total = Tokens.Typography.numeralLg.sized(64).relative(to: .largeTitle)
}

struct TypeStyleModifier: ViewModifier {
    let token: TypeToken
    let uppercase: Bool

    func body(content: Content) -> some View {
        content
            .font(token.font)
            .tracking(token.tracking * token.size)
            .lineSpacing(max(0, token.lineHeight - token.size) / 2)
            .textCase(uppercase ? .uppercase : nil)
    }
}

extension View {
    func typeStyle(_ token: TypeToken, uppercase: Bool = false) -> some View {
        modifier(TypeStyleModifier(token: token, uppercase: uppercase))
    }

    /// Small uppercase label in the muted color.
    func labelStyle() -> some View {
        typeStyle(.label, uppercase: true).foregroundStyle(Tokens.Colors.muted)
    }
}
