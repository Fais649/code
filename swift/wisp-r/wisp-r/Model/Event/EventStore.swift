import SwiftData
import SwiftUI

struct EventStore {
    static func loadAll(in modelContext: ModelContext, for calendar: EventCalendar) -> [Event] {
        let id = calendar.id
        let desc = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { $0.calendar.calendarIdentifier == id })
        let results = try? modelContext.fetch(desc)
        return results ?? []
    }
}
