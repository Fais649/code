import SwiftData
import SwiftUI

protocol Theme {
    var foregroundColor: Color { get }
    var backgroundColor: Color { get }
}

struct DefaultTheme: Theme {
    var foregroundColor: Color {
        .gray
    }

    var backgroundColor: Color {
        .gray.mix(with: .black, by: 0.4)
    }
}

struct Default {
    enum Shade {
        case primary, secondary, third, fourth, fifth

        var value: CGFloat {
            switch self {
            case .secondary:
                0.75
            case .third:
                0.5
            case .fourth:
                0.25
            case .fifth:
                0.12
            default:
                1
            }
        }
    }

    static var blackHexString = "000000"
    static var whiteHexString = "FFFFFF"

    @AppStorage("darkMode")
    static var darkMode: Bool = true

    static var foregroundMixColor: Color {
        if Default.darkMode {
            return .white
        } else {
            return .black
        }
    }

    static var backgroundMixColor: Color {
        if Default.darkMode {
            return .black
        } else {
            return .white
        }
    }

    static func backgroundMixFactor(for color: Color) -> CGFloat {
        if color.toHexString.contains(blackHexString) {
            return 1
        }
        return 0.6
    }

    static func foregroundMixFactor(for color: Color) -> CGFloat {
        if color.toHexString.contains(blackHexString) {
            return 1
        }
        return 0.3
    }

    @AppStorage("defaultColorHexString")
    static var defaultColorHexString: String = "#888888"

    static var color: Color {
        Color(hex: defaultColorHexString)
    }

    static func setColor(_ color: Color) {
        defaultColorHexString = color.toHexString
    }

    static var foregroundColor: Color {
        color.mix(with: foregroundMixColor, by: foregroundMixFactor(for: color))
    }

    static func foregroundColor(for color: Color) -> Color {
        color.mix(with: foregroundMixColor, by: foregroundMixFactor(for: color))
    }

    static var backgroundColor: Color {
        color.mix(with: backgroundMixColor, by: backgroundMixFactor(for: color))
    }

    static func backgroundColor(for color: Color, mixBy mixFactor: Double = 0.8) -> Color {
        color.mix(with: backgroundMixColor, by: mixFactor)
    }

    @ViewBuilder
    static func toolbarBackground(for color: Color = Default.color) -> some View {
        Rectangle()
            .fill(backgroundColor(for: color, mixBy: 0.6))
            .ignoresSafeArea()
    }

    @ViewBuilder
    static func rowBackground(for color: Color = Default.color) -> some View {
        Rectangle()
            .fill(backgroundColor(for: color, mixBy: 0.6))
            .ignoresSafeArea()
    }

    @ViewBuilder
    static func sheetBackground(for color: Color = Default.color) -> some View {
        rowBackground(for: color)
    }

    @ViewBuilder
    static func screenBackground(for color: Color = Default.color) -> some View {
        Rectangle()
            .fill(backgroundColor(for: color))
            .ignoresSafeArea()
    }

    @AppStorage("defaultCalendarTitle") static var defaultCalendarTitle: String = ""
    @AppStorage("defaultCalendarID") static var defaultCalendarID: String = ""

    static func isDefault(eventCalendar: EventCalendar) -> Bool {
        eventCalendar.id == defaultCalendarID
    }

    static func resetDefaultCalendar() {
        defaultCalendarID = ""
        defaultCalendarTitle = ""
    }

    static func setDefault(eventCalendar: EventCalendar) {
        eventCalendar.activate()
        defaultCalendarID = eventCalendar.id
        defaultCalendarTitle = eventCalendar.title
    }
}
