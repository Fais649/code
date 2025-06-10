import SwiftUI

extension Date {
    func settingTime(from time: Date, using calendar: Calendar = .current) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        let timeComponents = calendar.dateComponents(
            [.hour, .minute, .second, .nanosecond], from: time)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second
        combined.nanosecond = timeComponents.nanosecond
        return calendar.date(from: combined) ?? self
    }

    mutating func setTime(from time: Date, using calendar: Calendar = .current) {
        self = settingTime(from: time, using: calendar)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isPastDay: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let date = Calendar.current.startOfDay(for: self)
        return date < today
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r: UInt64
        let g: UInt64
        let b: UInt64
        let a: UInt64

        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 0xFF)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0x88, 0x88, 0x88, 0xFF)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }

    var toHexString: String {
        #if os(iOS) || os(tvOS) || os(watchOS)
            let uiColor = UIColor(self)
        #else
            let uiColor = NSColor(self)
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        let ai = Int((a * 255).rounded())

        if ai < 255 {
            return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
        } else {
            return String(format: "#%02X%02X%02X", ri, gi, bi)
        }
    }
}
