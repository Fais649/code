//
//  wisprApp.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 08.11.24.
//

import EventKit
import SwiftData
import SwiftUI

@main
struct wisprApp: App {
    @State var dayViewModel: DayViewModel = .init(datasource: .shared)
    @State var userViewModel: UserViewModel = .init(datasource: .shared)
    @State var sharedState: SharedState = .init()

    var body: some Scene {
        WindowGroup {
            DayView()
                .environment(dayViewModel)
                .environment(userViewModel)
                .environment(sharedState)
                .preferredColorScheme(.dark)
                .colorScheme(.dark)
                .font(.custom("GohuFont11NFM", size: 14))
        }
    }
}

enum Sheet {
    case main, createEvent, editEvent, createTodo, editTodo, editSettings, datePicker
}

enum Field: Hashable {
    case todo
    case event
}

@Observable
class SharedState {
    var activeSheet: Sheet = .main
    var item: Item?

    func activateSheet(_ sheet: Sheet, item: Item? = nil) {
        activeSheet = sheet
        self.item = item
    }

    func isActiveItem(item: Item) -> Bool {
        return item.uuid == item.uuid
    }
}

class SwiftDataService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    let eventStore: EKEventStore = .init()
    var accessToCalendar: Bool = false

    @MainActor
    static let shared = SwiftDataService()

    @MainActor
    private init() {
        modelContainer = try! ModelContainer(
            for: Day.self, User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: false), ModelConfiguration(isStoredInMemoryOnly: false)
        )

        modelContext = modelContainer.mainContext
        requestAccessToCalendar()
    }

    func requestAccessToCalendar() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted, error == nil {
                self.accessToCalendar = true
            }
        }
    }

    func fetchAvailableEventCalendars() -> [EKCalendar] {
        let calendars = eventStore.calendars(for: .event)
        return calendars
    }

    func fetchActiveCalendars(activeCalendars: [ActiveCalendar]) -> [EKCalendar] {
        var calendars: [EKCalendar] = []
        for activeCalendar in activeCalendars {
            if let ekCal = eventStore.calendar(withIdentifier: activeCalendar.calendarIdentifier) {
                calendars.append(ekCal)
            }
        }
        return calendars
    }

    func fetchDays() -> [Day] {
        do {
            return try modelContext.fetch(FetchDescriptor<Day>())
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchLocalEvents() -> [Event] {
        do {
            return try modelContext.fetch(FetchDescriptor<Event>())
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchWeek(start: Date, end: Date) -> [Day] {
        do {
            let days = try modelContext.fetch(FetchDescriptor<Day>()).filter { start < $0.timestamp && $0.timestamp <= end }
            return days
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchDay(date: Date) -> Day {
        do {
            let day = try modelContext.fetch(FetchDescriptor<Day>()).first { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }

            if let result = day {
                return result
            } else {
                let newDay = Day(timestamp: date)
                addDay(newDay)
                return newDay
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchUser() -> User {
        do {
            let user = try modelContext.fetch(FetchDescriptor<User>()).first
            if let result = user {
                return result
            } else {
                let newUser = User()
                modelContext.insert(newUser)
                save()
                return newUser
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func addDay(_ day: Day) {
        modelContext.insert(day)
        save()
    }

    func createTodo(day: Day, title: String = "") -> Todo {
        let todo = Todo(timestamp: Date(), title: title)
        day.todos.append(todo)
        save()
        return todo
    }

    func deleteTodo(day: Day, todo: Todo) {
        if let index = day.todos.firstIndex(where: { $0.id == todo.id }) {
            day.todos.remove(at: index)
            save()
        }
    }

    func createEventInCalendar(title: String, start: Date, end: Date) -> Event? {
        if !accessToCalendar {
            requestAccessToCalendar()
        }

        if accessToCalendar {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = title
            ekEvent.startDate = start
            ekEvent.endDate = end
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents

            try? eventStore.save(ekEvent, span: .thisEvent)
            let eventDay = fetchDay(date: ekEvent.startDate)
            let event = Event(eventIdentifier: ekEvent.eventIdentifier, start: start, end: end, title: title)
            eventDay.events.append(event)
            save()
            return event
        }
        return nil
    }

    func updateEventInCalendar(day: Day, event: Event) {
        if !accessToCalendar {
            requestAccessToCalendar()
        }

        let calEvent = eventStore.event(withIdentifier: event.eventIdentifier)

        if event.title.isEmpty || calEvent == nil {
            deleteEventInCalendar(day: day, event: event)
            return
        }

        calEvent?.title = event.title
        calEvent?.startDate = event.start
        calEvent?.endDate = event.end

        if let result = calEvent {
            try? eventStore.save(result, span: .thisEvent)
        }

        if !Calendar.current.isDate(event.start, inSameDayAs: day.timestamp) {
            let eventDay = fetchDay(date: event.start)
            eventDay.events.append(event)
            deleteEvent(day: day, event: event)
        }
        save()
    }

    func deleteEvent(day: Day, event: Event) {
        if let index = day.events.firstIndex(where: { $0.eventIdentifier == event.eventIdentifier }) {
            day.events.remove(at: index)
            save()
        }
    }

    func deleteEventInCalendar(day: Day, event: Event) {
        if !accessToCalendar {
            requestAccessToCalendar()
        }

        if accessToCalendar {
            if let eventToDelete = eventStore.event(withIdentifier: event.eventIdentifier) {
                do {
                    try eventStore.remove(eventToDelete, span: .thisEvent)
                } catch {
                    print("Error deleting event: \(error.localizedDescription)")
                }
                if let index = day.events.firstIndex(where: { $0.eventIdentifier == event.eventIdentifier }) {
                    day.events.remove(at: index)
                    save()
                }
            }
        }
    }
}
