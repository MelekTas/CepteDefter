import SwiftUI

/// Uygulama genelinde kullanılan renk ve tipografi tokenları.
enum Theme {
    // MARK: Colors
    static let ink       = Color(hex: "1B2430")
    static let paper     = Color(hex: "F6F3EC")
    static let paperDark = Color(hex: "EDE8DC")
    static let sage      = Color(hex: "7C9A82")
    static let amber     = Color(hex: "E8A33D")
    static let clay      = Color(hex: "C1543C")
    static let slate     = Color(hex: "8A9199")
    static let hairline  = Color(hex: "DAD3C3")

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom("Fraunces-SemiBold", size: size) // .weight(...) kısmını kaldırdık
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func statusColor(for percent: Double) -> Color {
        switch percent {
        case ..<0.8: return sage
        case 0.8..<1.0: return amber
        default: return clay
        }
    }
}

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
