import SwiftData
import SwiftUI

struct EventCalendarStore {
    static func loadAllActive(in modelContext: ModelContext) -> [EventCalendar] {
        let desc = FetchDescriptor<EventCalendar>(
            predicate: #Predicate<EventCalendar> { $0.active == true })
        let results = try? modelContext.fetch(desc)
        return results ?? []
    }

    static func load(in modelContext: ModelContext, by calendarIdentifier: String) -> EventCalendar?
    {
        let desc = FetchDescriptor<EventCalendar>(
            predicate: #Predicate<EventCalendar> { $0.calendarIdentifier == calendarIdentifier })
        let results = try? modelContext.fetch(desc).first
        return results
    }

    static func loadDefault(in modelContext: ModelContext) -> EventCalendar? {
        let defaultID = Default.defaultCalendarID
        let desc = FetchDescriptor<EventCalendar>(
            predicate: #Predicate<EventCalendar> { $0.calendarIdentifier == defaultID })
        let results = try? modelContext.fetch(desc).first
        return results
    }

    static func loadAll(in modelContext: ModelContext) -> [EventCalendar] {
        let desc = FetchDescriptor<EventCalendar>()
        let results = try? modelContext.fetch(desc)
        return results ?? []
    }
}
