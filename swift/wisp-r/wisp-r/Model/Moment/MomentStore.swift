import EventKit
import SwiftData
import SwiftUI

struct MomentStore {
    static func timelinePredicate(timelineID: UUID) -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.timeline?.id == timelineID
        }
    }

    static func notePredicate() -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.isTask == false && moment.event == nil
        }
    }

    static func eventPredicate() -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.event != nil
        }
    }

    static func taskPredicate() -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.isTask
        }
    }

    static func imagesPredicate() -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.images != nil
        }
    }

    static func audioPredicate() -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.audio != nil
        }
    }

    static func pinnedPredicate(_ isPinned: Bool = true) -> Predicate<Moment> {
        #Predicate<Moment> { moment in
            moment.pinned == isPinned
        }
    }

    static func create() -> Moment {
        return Moment(position: 0)
    }

    static func move(_ moment: Moment, to date: Date, in modelContext: ModelContext) {
        guard
            let day = try? modelContext.fetch(
                FetchDescriptor<Day>(
                    predicate: DayStore.datePredicate(date: date))
            ).first
        else { return }

        moment.day = day
        try? modelContext.save()
    }

    static func move(
        _ moments: [Moment],
        from indexSet: IndexSet,
        to newIndex: Int,
        in modelContext: ModelContext
    ) {
        var newMoments = moments.sorted(by: { $0.position < $1.position })
        newMoments.move(fromOffsets: indexSet, toOffset: newIndex)

        for (i, moment) in newMoments.enumerated() {
            moment.position = i
        }

        try? modelContext.save()
    }

    static func attachEvent(ekEvent: EKEvent, to moment: Moment, in modelContext: ModelContext) {
        guard
            let cal = EventCalendarStore.load(
                in: modelContext, by: ekEvent.calendar.calendarIdentifier),
            let day = try? modelContext.fetch(
                FetchDescriptor<Day>(
                    predicate: DayStore.datePredicate(date: ekEvent.startDate))
            ).first
        else { return }

        let event = Event(
            eventIdentifier: ekEvent.eventIdentifier,
            calendar: cal,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate
        )

        modelContext.insert(event)

        if cal.active == false {
            EKCalendarService.activate(cal, in: modelContext)
        }

        moment.day = day
        moment.event = event
        moment.text = ekEvent.title
        try? modelContext.save()
    }
}
