import SwiftUI

struct ColorData: RawRepresentable, Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(color: Color) {
        #if os(iOS) || os(tvOS) || os(watchOS)
            let uiColor = UIColor(color)
        #else
            let uiColor = NSColor(color)
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r)
        green = Double(g)
        blue = Double(b)
        alpha = Double(a)
    }

    init(rawValue: String = "") {
        let hex = rawValue.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let length = hex.count
        if let intVal = UInt64(hex, radix: 16), length == 6 || length == 8 {
            if length == 6 {
                red = Double((intVal >> 16) & 0xFF) / 255.0
                green = Double((intVal >> 8) & 0xFF) / 255.0
                blue = Double(intVal & 0xFF) / 255.0
                alpha = 1.0
            } else {
                red = Double((intVal >> 24) & 0xFF) / 255.0
                green = Double((intVal >> 16) & 0xFF) / 255.0
                blue = Double((intVal >> 8) & 0xFF) / 255.0
                alpha = Double(intVal & 0xFF) / 255.0
            }
        } else {
            let grayValue = Double(0x88) / 255.0
            red = grayValue
            green = grayValue
            blue = grayValue
            alpha = 1.0
        }
    }

    var rawValue: String {
        toHexString()
    }

    var asColor: Color {
        Color(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }

    static func getHexString(colorData: ColorData) -> String {
        return toHexString(colorData: colorData)
    }

    static func toHexString(colorData: ColorData) -> String {
        let r = UInt8((colorData.red * 255).rounded())
        let g = UInt8((colorData.green * 255).rounded())
        let b = UInt8((colorData.blue * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    func toHexString(includeAlpha: Bool = true) -> String {
        let r = UInt8((red * 255).rounded())
        let g = UInt8((green * 255).rounded())
        let b = UInt8((blue * 255).rounded())
        let a = UInt8((alpha * 255).rounded())

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

@objc(UIColorValueTransformer)
final class UIColorValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return UIColor.self
    }

    // return data
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            return nil
        }
    }

    // return UIColor
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }

        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            return color
        } catch {
            return nil
        }
    }
}
