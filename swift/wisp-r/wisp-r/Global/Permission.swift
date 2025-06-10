import EventKit
import SwiftData
import SwiftUI

struct Permission {
    @AppStorage("hasCalendarAccessPermission")
    static var hasCalendarAccessPermission: Bool = false

    static func requestAccessToCalendar() async -> Bool {
        guard !hasCalendarAccessPermission else { return true }
        let result = try? await EKCalendarService.ekEventStore.requestFullAccessToEvents()
        hasCalendarAccessPermission = result ?? false
        return hasCalendarAccessPermission
    }
}
