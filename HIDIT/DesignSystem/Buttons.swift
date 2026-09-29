import SwiftUI

/// The one main action per screen: a 72 pt ink pill with white text.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(.button)
            .foregroundStyle(Tokens.Colors.onInk)
            .frame(maxWidth: .infinity, minHeight: Layout.primaryHeight)
            .background(Tokens.Colors.ink, in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? Layout.pressedScale : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Outlined pill, for End run.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(.button)
            .foregroundStyle(Tokens.Colors.ink)
            .frame(maxWidth: .infinity, minHeight: Layout.primaryHeight)
            .overlay(Capsule().strokeBorder(Tokens.Colors.ink, lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? Layout.pressedScale : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Text-only button, for Cancel.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(.quietButton)
            .foregroundStyle(Tokens.Colors.muted)
            .frame(maxWidth: .infinity, minHeight: Layout.quietHeight)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Small outlined pill, for the test-cue buttons.
struct OutlinePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(.small)
            .foregroundStyle(Tokens.Colors.ink)
            .frame(maxWidth: .infinity, minHeight: Layout.iconButton)
            .overlay(Capsule().strokeBorder(Tokens.Colors.ink, lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? Layout.pressedScale : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle { static var primary: PrimaryButtonStyle { .init() } }
extension ButtonStyle where Self == SecondaryButtonStyle { static var secondary: SecondaryButtonStyle { .init() } }
extension ButtonStyle where Self == QuietButtonStyle { static var quiet: QuietButtonStyle { .init() } }
extension ButtonStyle where Self == OutlinePillButtonStyle { static var outlinePill: OutlinePillButtonStyle { .init() } }

/// Taupe squircle icon button with a white glyph.
struct IconButton: View {
    let icon: AxisIcon
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image
                .frame(width: 22, height: 22)
                .foregroundStyle(Tokens.Colors.onInk)
                .frame(width: Layout.iconButton, height: Layout.iconButton)
                .background(Tokens.Colors.taupe, in: RoundedRectangle(cornerRadius: Tokens.Radius.radiusButton, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.radiusButton, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(label)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? Layout.pressedScale : 1)
    }
}
