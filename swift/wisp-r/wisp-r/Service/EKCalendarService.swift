import EventKit
import EventKitUI
import SwiftData
import SwiftUI

struct EKCalendarService {
    static var ekEventStore: EKEventStore = .init()

    static func importEKCalendars(in modelContext: ModelContext) {
        guard Permission.hasCalendarAccessPermission else { return }

        let existing = EventCalendarStore.loadAll(in: modelContext)

        let defaultCalID = ekEventStore.defaultCalendarForNewEvents?.calendarIdentifier
        let calendars = ekEventStore.calendars(for: .event)

        for cal in calendars {
            if let c = existing.first(where: { $0.calendarIdentifier == cal.calendarIdentifier }) {
                c.title = cal.title
                c.sourceTitle = cal.source.title
            } else {
                let eventCalendar = EventCalendar(
                    calendarIdentifier: cal.calendarIdentifier,
                    title: cal.title,
                    sourceTitle: cal.source.title
                )

                modelContext.insert(eventCalendar)
                if eventCalendar.id == defaultCalID {
                    Default.setDefault(eventCalendar: eventCalendar)
                    eventCalendar.activate()
                }
            }
        }
        syncEKCalendars(in: modelContext)
    }

    static func activate(
        _ eventCalendar: EventCalendar,
        in modelContext: ModelContext
    ) {
        guard Permission.hasCalendarAccessPermission else { return }
        guard let ekCal = ekEventStore.calendar(withIdentifier: eventCalendar.calendarIdentifier)
        else { return }

        let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 60 * 60)
        let oneYearAhead = Date().addingTimeInterval(365 * 24 * 60 * 60)
        let predicate = ekEventStore.predicateForEvents(
            withStart: oneYearAgo,
            end: oneYearAhead,
            calendars: [ekCal]
        )

        let ekEvents = ekEventStore.events(matching: predicate)

        let existingEvents = eventCalendar.events
        var internalByID: [String: Event] = [:]
        for evt in existingEvents {
            internalByID[evt.eventIdentifier] = evt
        }

        var seenEKIDs = Set<String>()
        for ekEvt in ekEvents {
            guard let ekID = ekEvt.eventIdentifier else { continue }
            seenEKIDs.insert(ekID)

            createNewEvent(
                in: modelContext,
                ekID: ekID,
                ekEvt: ekEvt,
                eventCalendar: eventCalendar
            )
        }

        for stored in existingEvents {
            if !seenEKIDs.contains(stored.eventIdentifier) {
                modelContext.delete(stored)
            }
        }

        eventCalendar.activate()
        try? modelContext.save()
    }

    static func update(_ event: Event) {
        let store = ekEventStore

        guard let moment = event.moment,
            let ekEvent = store.event(withIdentifier: event.eventIdentifier)
        else {
            return
        }

        ekEvent.title = moment.text
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay

        if let loc = event.moment?.location, let lat = loc.lat, let long = loc.long {
            ekEvent.location = loc.name

            let structured = EKStructuredLocation(title: loc.name)
            structured.geoLocation = CLLocation(
                latitude: lat,
                longitude: long
            )
            ekEvent.structuredLocation = structured
        } else {
            ekEvent.location = nil
            ekEvent.structuredLocation = nil
        }

        do {
            try store.save(ekEvent, span: .thisEvent)
        } catch {
            print("Failed to save event to Calendar: \(error)")
        }
    }

    static func delete(_ event: Event, in modelContext: ModelContext) {
        guard let ekEvent = ekEventStore.event(withIdentifier: event.eventIdentifier) else {
            return
        }
        if let moment = event.moment {
            moment.event = nil
        }
        modelContext.delete(event)
        try? modelContext.save()
        try? ekEventStore.remove(ekEvent, span: .thisEvent)
    }

    static func deactivate(_ eventCalendar: EventCalendar, in modelContext: ModelContext) {
        guard Permission.hasCalendarAccessPermission else { return }
        let events = EventStore.loadAll(in: modelContext, for: eventCalendar)

        for e in events {
            if let m = e.moment {
                modelContext.delete(m)
            }
            modelContext.delete(e)
        }

        eventCalendar.deactivate()
        try? modelContext.save()
    }

    static func syncEKCalendars(in modelContext: ModelContext) {
        guard Permission.hasCalendarAccessPermission else { return }
        let activeCalendars = EventCalendarStore.loadAllActive(in: modelContext)
        let activeByID = Dictionary(
            uniqueKeysWithValues: activeCalendars.map { ($0.calendarIdentifier, $0) }
        )

        let ekCalendars = ekEventStore.calendars(for: .event)
        let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 60 * 60)
        let oneYearAhead = Date().addingTimeInterval(365 * 24 * 60 * 60)

        for ekCal in ekCalendars {
            guard let eventCalendar = activeByID[ekCal.calendarIdentifier] else { continue }
            let predicate = ekEventStore.predicateForEvents(
                withStart: oneYearAgo,
                end: oneYearAhead,
                calendars: [ekCal]
            )

            let ekEvents = ekEventStore.events(matching: predicate)
            let existingEvents = eventCalendar.events
            var internalByID = [String: Event]()
            for evt in existingEvents {
                internalByID[evt.eventIdentifier] = evt
            }

            var seenEKIDs = Set<String>()
            for ekEvt in ekEvents {
                guard let ekID = ekEvt.eventIdentifier else { continue }
                seenEKIDs.insert(ekID)

                if let stored = internalByID[ekID] {

                    if stored.moment == nil {
                        let day =
                            try? modelContext.fetch(
                                FetchDescriptor<Day>(
                                    predicate: DayStore.datePredicate(date: ekEvt.startDate))
                            ).first ?? Day(date: ekEvt.startDate, moments: [])

                        let moment = Moment(day: day, position: 0, text: ekEvt.title)
                        modelContext.insert(moment)
                        moment.event = stored
                    }

                    updateEvent(stored: stored, ekEvt: ekEvt)
                    guard let location = stored.moment?.location else { continue }
                    updateLocation(stored: stored, location: location, ekEvt: ekEvt)
                } else {
                    createNewEvent(
                        in: modelContext,
                        ekID: ekID,
                        ekEvt: ekEvt,
                        eventCalendar: eventCalendar)
                }
            }

            for stored in existingEvents {
                if !seenEKIDs.contains(stored.eventIdentifier) {
                    modelContext.delete(stored)
                }
            }
        }

        try? modelContext.save()
    }

    static private func createNewEvent(
        in modelContext: ModelContext, ekID: String, ekEvt: EKEvent, eventCalendar: EventCalendar
    ) {
        let day =
            try? modelContext.fetch(
                FetchDescriptor<Day>(predicate: DayStore.datePredicate(date: ekEvt.startDate))
            ).first ?? Day(date: ekEvt.startDate, moments: [])

        let moment = Moment(day: day, position: 0, text: ekEvt.title)

        modelContext.insert(moment)

        let newEvent = Event(
            eventIdentifier: ekID,
            calendar: eventCalendar,
            startDate: ekEvt.startDate,
            endDate: ekEvt.endDate,
        )
        newEvent.isAllDay = ekEvt.isAllDay
        modelContext.insert(newEvent)
        moment.event = newEvent
    }

    static private func updateEvent(stored: Event, ekEvt: EKEvent) {
        if stored.startDate != ekEvt.startDate {
            stored.startDate = ekEvt.startDate
        }
        if stored.endDate != ekEvt.endDate {
            stored.endDate = ekEvt.endDate
        }
        if stored.isAllDay != ekEvt.isAllDay {
            stored.isAllDay = ekEvt.isAllDay
        }
    }

    static private func updateLocation(stored: Event, location: Location, ekEvt: EKEvent) {
        if let loc = ekEvt.location, location.name != loc {
            location.name = loc
        }

        if let structured = ekEvt.structuredLocation,
            let coord = structured.geoLocation?.coordinate
        {
            if location.lat != coord.latitude {
                location.lat = coord.latitude
            }

            if location.long != coord.longitude {
                location.long = coord.longitude
            }
        } else {
            stored.moment?.location = nil
        }
    }
}
