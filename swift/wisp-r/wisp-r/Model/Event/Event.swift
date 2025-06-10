import MapKit
import SwiftData
import SwiftUI

@Model
final class Event: Identifiable {
    var id: String {
        eventIdentifier
    }

    var eventIdentifier: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool

    @Relationship(deleteRule: .nullify, inverse: \EventCalendar.events)
    var calendar: EventCalendar

    var moment: Moment?

    init(
        eventIdentifier: String,
        calendar: EventCalendar,
        startDate: Date,
        endDate: Date
    ) {
        self.eventIdentifier = eventIdentifier
        self.calendar = calendar
        self.startDate = startDate
        self.endDate = endDate
        isAllDay = false
    }

    var startTimeString: String {
        startDate.formatted(.dateTime.hour().minute())
    }

    var endTimeString: String {
        endDate.formatted(.dateTime.hour().minute())
    }
}
