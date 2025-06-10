import SwiftUI

struct UserSetting {
    @AppStorage("defaultColorHex")
    static var defaultColor: ColorData = .init()

    @AppStorage("defaultEKCalendarID")
    static var defaultEKCalendarID: String = ""

    @AppStorage("displayName")
    static var displayName: String = ""
}
