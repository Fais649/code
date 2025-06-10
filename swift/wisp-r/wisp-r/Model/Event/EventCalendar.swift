import SwiftData
import SwiftUI

@Model
final class EventCalendar: Identifiable {

    var id: String {
        calendarIdentifier
    }

    var isDefault: Bool {
        Default.isDefault(eventCalendar: self)
    }

    var title: String
    var sourceTitle: String
    var calendarIdentifier: String
    var events: [Event] = []
    var active: Bool = false

    var isActive: Bool {
        active
    }

    func toggleActive() {
        active = !active
    }

    func activate() {
        active = true
    }

    func deactivate() {
        active = false
    }

    init(calendarIdentifier: String, title: String, sourceTitle: String) {
        self.calendarIdentifier = calendarIdentifier
        self.title = title
        self.sourceTitle = sourceTitle
    }
}
