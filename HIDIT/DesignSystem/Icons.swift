import SwiftUI

/// Thin outline icons (1.5 pt stroke), drawn as shapes so they match the prototype exactly.
enum AxisIcon {
    case sliders
    case back
    case chevron
    case check
    case lock
    case info

    var image: some View {
        IconShape(kind: self)
            .stroke(style: StrokeStyle(lineWidth: self == .check ? 2 : 1.5, lineCap: .round, lineJoin: .round))
    }
}

/// Icon paths on a 24 x 24 grid, scaled to the frame.
struct IconShape: Shape {
    let kind: AxisIcon

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let o = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
        var path = Path()
        switch kind {
        case .sliders:
            path.move(to: p(4, 7)); path.addLine(to: p(14, 7))
            path.move(to: p(18, 7)); path.addLine(to: p(20, 7))
            path.move(to: p(4, 17)); path.addLine(to: p(6, 17))
            path.move(to: p(10, 17)); path.addLine(to: p(20, 17))
            path.addEllipse(in: CGRect(x: o.x + 14 * s, y: o.y + 5 * s, width: 4 * s, height: 4 * s))
            path.addEllipse(in: CGRect(x: o.x + 6 * s, y: o.y + 15 * s, width: 4 * s, height: 4 * s))
        case .back:
            path.move(to: p(15, 5)); path.addLine(to: p(8, 12)); path.addLine(to: p(15, 19))
        case .chevron:
            path.move(to: p(9, 5)); path.addLine(to: p(16, 12)); path.addLine(to: p(9, 19))
        case .check:
            path.move(to: p(5, 12.5)); path.addLine(to: p(9.5, 17)); path.addLine(to: p(19, 7.5))
        case .lock:
            path.addRoundedRect(in: CGRect(x: o.x + 5 * s, y: o.y + 11 * s, width: 14 * s, height: 9 * s), cornerSize: CGSize(width: 2 * s, height: 2 * s))
            path.move(to: p(8, 11)); path.addLine(to: p(8, 8))
            path.addArc(center: p(12, 8), radius: 4 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: p(16, 11))
        case .info:
            path.addEllipse(in: CGRect(x: o.x + 3 * s, y: o.y + 3 * s, width: 18 * s, height: 18 * s))
            path.move(to: p(12, 11)); path.addLine(to: p(12, 16))
            path.move(to: p(12, 8)); path.addLine(to: p(12.01, 8))
        }
        return path
    }
}

/// The heavy square-cap diagonal arrow. Up-right for work, down-right for recover and totals.
struct DiagonalArrow: View {
    enum Direction { case upRight, downRight }
    let direction: Direction
    var color: Color = Tokens.Colors.ink

    var body: some View {
        ArrowShape(direction: direction)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
            .frame(width: Layout.arrowSize, height: Layout.arrowSize)
            .accessibilityHidden(true)
    }
}

struct ArrowShape: Shape {
    let direction: DiagonalArrow.Direction

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 56
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        switch direction {
        case .upRight:
            path.move(to: p(14, 42)); path.addLine(to: p(42, 14))
            path.move(to: p(22, 14)); path.addLine(to: p(42, 14)); path.addLine(to: p(42, 34))
        case .downRight:
            path.move(to: p(14, 14)); path.addLine(to: p(42, 42))
            path.move(to: p(42, 22)); path.addLine(to: p(42, 42)); path.addLine(to: p(22, 42))
        }
        return path
    }
}
