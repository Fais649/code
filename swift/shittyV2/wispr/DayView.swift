//
//  DayView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 08.11.24.
//

import EventKit
import SwiftData
import SwiftUI

struct DayView: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(SharedState.self) private var sharedState
    @State private var ratio: CGFloat = 0.3
    @State private var detent: PresentationDetent = .fraction(0.3)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    SettingsView()
                    VStack {
                        ListView()
                    }
                    .scrollContentBackground(.hidden)
                    .ignoresSafeArea()
                    .listSectionSpacing(15)
                    .listRowSpacing(4)
                    .listRowSeparator(.hidden)
                    .padding(.horizontal)
                    .frame(maxHeight: geo.size.height * (1 - ratio))
                    .sheet(isPresented: Binding(
                        get: { sharedState.activeSheet == .main },
                        set: { _ in }
                    )) {
                        DaySheetView(detent: $detent, ratio: $ratio)
                            .interactiveDismissDisabled()
                            .presentationDragIndicator(.hidden)
                            .presentationBackgroundInteraction(.enabled)
                            .presentationCornerRadius(0)
                            .presentationBackground {
                                Color.black.ignoresSafeArea()
                            }.onAppear {
                                detent = .fraction(0.3)
                            }
                    }

                    Spacer()
                }
            }
        }
    }
}

struct ListView: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(SharedState.self) private var sharedState
    @State var isTarget: Bool = false

    var body: some View {
        if userViewModel.user.showCompleted {
            ForEach(dayViewModel.fetchSortedEvents(activeCalendars: userViewModel.user.activeCalendars)) { event in
                if event.end < Date() {
                    let isEditing = (sharedState.activeSheet == .editEvent && sharedState.isActiveItem(item: event))
                    EventView(event: event, isEditing: isEditing)
                        .font(.custom("GohuFont11NFM", size: 16))
                        .foregroundStyle(.gray)
                        .listRowSeparatorTint(.black)
                        .listRowBackground(Color.black.ignoresSafeArea())
                        .dropDestination(for: String.self) { strings, _ in
                            withAnimation {
                                guard let movedTodo = strings.first else {
                                    return false
                                }

                                dayViewModel.dropTodoOnEvent(event: event, todoUuid: movedTodo)

                                return true
                            }
                        } isTargeted: { isTargeted in
                            isTarget = isTargeted
                        }
                }
            }
        }

        List {
            ForEach(dayViewModel.fetchSortedEvents(activeCalendars: userViewModel.user.activeCalendars)) { event in
                if event.end >= Date() {
                    let isEditing = (sharedState.activeSheet == .editEvent && sharedState.isActiveItem(item: event))
                    EventView(event: event, isEditing: isEditing)
                        .font(.custom("GohuFont11NFM", size: 16))
                        .listRowSeparatorTint(.black)
                        .blendMode(.difference)
                        .listRowBackground(Color.black)
                        .dropDestination(for: String.self) { strings, _ in
                            withAnimation {
                                print("DROP")
                                guard let movedTodo = strings.first else {
                                    return false
                                }

                                dayViewModel.dropTodoOnEvent(event: event, todoUuid: movedTodo)

                                return true
                            }
                        } isTargeted: { isTargeted in
                            isTarget = isTargeted
                        }
                }
            }
        }

        List {
            ForEach(dayViewModel.fetchSortedTodos()) { todo in
                if !todo.done {
                    let isEditing = (sharedState.activeSheet == .editTodo && sharedState.isActiveItem(item: todo))
                    TodoView(todo: todo, isEditing: isEditing)
                        .draggable(todo.uuid.uuidString)
                        .font(.custom("GohuFont11NFM", size: 16))
                        .listRowSeparatorTint(.black)
                        .listRowBackground(Color.black.ignoresSafeArea())
                        .listRowSpacing(0)
                }

                if userViewModel.user.showDone {
                    ForEach(dayViewModel.fetchSortedTodos()) { todo in
                        if todo.done {
                            let isEditing = (sharedState.activeSheet == .editTodo && sharedState.isActiveItem(item: todo))
                            TodoView(todo: todo, isEditing: isEditing)
                                .font(.custom("GohuFont11NFM", size: 16))
                                .foregroundStyle(.gray)
                                .listRowSeparatorTint(.black)
                                .listRowSpacing(0)
                                .listRowBackground(Color.black.ignoresSafeArea())
                        }
                    }
                }
            }
        }
    }
}

struct DaySheetView: View {
    @Binding var detent: PresentationDetent
    @Binding var ratio: CGFloat
    @State var alert: Bool = false
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(SharedState.self) private var sharedState
    @State var pickDate = false
    @State var datepicked: Date = .init()

    var body: some View {
        @Bindable var dayViewModel = dayViewModel
        VStack {
            if !pickDate {
                noteForm
            }

            HStack {
                Spacer()
                controls
                Spacer()

            }.padding()
        }
        .presentationDetents(
            [.fraction(0.3), .fraction(0.5), .fraction(0.6), .fraction(0.8), .fraction(1)],
            selection: $detent
        ).onChange(of: detent) {
            withAnimation {
                switch detent {
                case .fraction(0.3):
                    ratio = 0.3
                case .fraction(0.5):
                    ratio = 0.5
                case .fraction(0.6):
                    ratio = 0.6
                case .fraction(0.8):
                    ratio = 0.8
                case .fraction(1):
                    ratio = 1.0
                default:
                    ratio = 0.3
                }
            }
        }
    }

    @ViewBuilder private var noteForm: some View {
        @Bindable var dayViewModel = dayViewModel
        DottedLine()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .frame(height: 1)
            .foregroundColor(.gray)
            .padding(.bottom, 8)
        VStack {
            TextField("note;", text: $dayViewModel.day.note.title)
                .textFieldStyle(.plain)

            TextEditor(text: $dayViewModel.day.note.text)
                .onChange(of: dayViewModel.day.note.text) {
                    dayViewModel.save()
                }
                .onChange(of: dayViewModel.day.note.title) {
                    dayViewModel.save()
                }
                .scrollContentBackground(.hidden)
        }.padding(20)
    }

    @ViewBuilder private var controls: some View {
        VStack {
            if pickDate {
                DottedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .frame(height: 1)
                    .foregroundColor(.gray)

                DatePicker(selection: $datepicked, displayedComponents: .date) {
                    Text(datepicked.formatted(date: .abbreviated, time: .omitted))
                }.datePickerStyle(.graphical)
                    .labelsHidden()
                    .presentationBackground {
                        Color.black.ignoresSafeArea()
                    }
                Button {
                    withAnimation {
                        datepicked = Date()
                        dayViewModel.updateDayTo(date: datepicked)
                        pickDate = false
                    }
                } label: {
                    Image(systemName: "circle")
                }
                .padding(.bottom, 15)
            }

            HStack {
                Spacer()
                newEventButton
                Spacer()

                Button(action: {
                    withAnimation {
                        if let result = Calendar.current.date(byAdding: .day, value: -1, to: datepicked) {
                            datepicked = result
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Button {
                    withAnimation {
                        pickDate.toggle()
                    }
                } label: {
                    Text(datepicked.formatted(date: .abbreviated, time: .omitted))
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        if let result = Calendar.current.date(byAdding: .day, value: 1, to: datepicked) {
                            datepicked = result
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                }

                Spacer()
                newTodoButton
                Spacer()
            }
            .onAppear {
                // datepicked = dayViewModel.day.timestamp
            }
            .onChange(of: pickDate) {
                detent = .fraction(pickDate ? 0.6 : 0.3)
            }
            .onChange(of: datepicked) {
                withAnimation {
                    dayViewModel.updateDayTo(date: datepicked)
                }
            }
        }
    }

    @ViewBuilder private var newEventButton: some View {
        Button(action: {
            if userViewModel.user.activeCalendars.isEmpty {
                alert = true
                return
            }

            if let event = dayViewModel.newEvent(
                start: datepicked,
                end: datepicked.addingTimeInterval(3600),
                title: ""
            ) {
                sharedState.activateSheet(.editEvent, item: event)
            }

            print("NEW_EVENT")

        }) {
            Image(systemName: "calendar")
        }
        .alert(isPresented: $alert) {
            Alert(title: Text("Sorry dumbass"),
                  message: Text("If you don't fucking select a calendar, how the fuck am I supposed to let you create a calendar event?!"),
                  dismissButton: .default(Text("Sorry for being so retarded")))
        }
    }

    @ViewBuilder private var newTodoButton: some View {
        Button(action: {
            let todo = dayViewModel.newTodo()
            sharedState.activateSheet(.editTodo, item: todo)
            print("NEW_TODO")

        }) {
            Image(systemName: "checkmark.square")
        }
    }
}

struct DateView: View {
    @Environment(DayViewModel.self) private var dayViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(SharedState.self) private var sharedState
    @Binding var pickDate: Bool
    @State var datepicked: Date = .init()

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                DatePicker(selection: $datepicked, displayedComponents: .date) {
                    Text(dayViewModel.day.timestamp.formatted(date: .abbreviated, time: .omitted))
                }.datePickerStyle(.graphical)
                    .labelsHidden()
                    .onChange(of: datepicked) {
                        withAnimation {
                            dayViewModel.updateDayTo(date: datepicked)
                        }
                    }
                    .padding()
                    .presentationBackground {
                        Color.black.ignoresSafeArea()
                    }

                Button {
                    withAnimation {
                        datepicked = Date()
                        dayViewModel.updateDayTo(date: datepicked)
                        pickDate = false
                    }
                } label: {
                    Image(systemName: "circle")
                }
                .offset(y: -15)
            }

            DottedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.bottom, 8) // Optional padding between line and content
        }.onAppear {
            datepicked = dayViewModel.day.timestamp
        }
    }
}

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview {
    DayView()
}

@MainActor
@Observable
class DayViewModel {
    private var calendar: Calendar = .current
    var user: User = .init()
    var day: Day = .init(timestamp: Date())
    var events: [Event] = []
    var todos: [Todo] = []

    private let datasource: SwiftDataService

    init(datasource: SwiftDataService) {
        self.datasource = datasource
        day = datasource.fetchDay(date: Date())
        user = datasource.fetchUser()
        events = fetchSortedEvents(activeCalendars: user.activeCalendars)
        todos = fetchSortedTodos()
    }

    func getTodo(todoUuid: String) -> Todo {
        let uuid = UUID(uuidString: todoUuid)
        return day.todos.first { $0.uuid == uuid }!
    }

    func dropTodoOnEvent(event: Event, todoUuid: String) {
        let todo = getTodo(todoUuid: todoUuid)
        // event.todos.append(todo)
        todo.event = event
        save()
    }

    func fetchSortedEvents(activeCalendars _: [ActiveCalendar]) -> [Event] {
        let activeCalendars = user.activeCalendars

        if activeCalendars.isEmpty {
            return []
        }

        let startOfDay = calendar.startOfDay(for: day.timestamp)

        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            fatalError("Failed to calculate end of day")
        }

        let predicate = getEventStore().predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: datasource.fetchActiveCalendars(activeCalendars: activeCalendars)
        )

        let localEvents = datasource.fetchLocalEvents()

        var ekEvents: [Event] = []
        for event in getEventStore().events(matching: predicate) {
            if let newEvent: Event = localEvents.first { $0.eventIdentifier == event.eventIdentifier } {
                newEvent.start = event.startDate
                newEvent.end = event.endDate
                newEvent.title = event.title
                save()
                ekEvents.append(newEvent)
            } else {
                let newEvent = Event(eventIdentifier: event.eventIdentifier, start: event.startDate, end: event.endDate, title: event.title)
                ekEvents.append(newEvent)
            }
        }

        events = ekEvents
        return events.sorted { $0.start < $1.start }
    }

    func fetchSortedTodos() -> [Todo] {
        return day.todos.filter { $0.event == nil }.sorted { $0.timestamp < $1.timestamp }
    }

    func stepDayBy(days: Int) {
        let newDate = calendar.date(byAdding: .day, value: days, to: day.timestamp) ?? day.timestamp.advanced(by: TimeInterval(86400 * days))
        day = datasource.fetchDay(date: newDate)
        events = fetchSortedEvents(activeCalendars: user.activeCalendars)
        todos = fetchSortedTodos()
        save()
    }

    func updateDayTo(date: Date) {
        day = datasource.fetchDay(date: date)
        events = fetchSortedEvents(activeCalendars: user.activeCalendars)
        todos = fetchSortedTodos()
        save()
    }

    func newTodo() -> Todo {
        let todo = datasource.createTodo(day: day)
        todos.append(todo)
        save()
        return todo
    }

    func deleteTodo(todo: Todo) {
        datasource.deleteTodo(day: day, todo: todo)
        save()
    }

    func newEvent(start: Date, end: Date, title: String) -> Event? {
        if let event = datasource.createEventInCalendar(title: title, start:
            start, end: end)
        {
            events.append(event)
            save()
            return event
        }
        return nil
    }

    func deleteEventInCalendar(event: Event) {
        datasource.deleteEventInCalendar(day: day, event: event)
        save()
    }

    func updateEventInCalendar(event: Event) {
        datasource.updateEventInCalendar(day: day, event: event)
        refresh()
        save()
    }

    func refresh() {
        updateDayTo(date: day.timestamp)
    }

    func getEventStore() -> EKEventStore {
        return datasource.eventStore
    }

    func save() {
        datasource.save()
    }
}

@MainActor
@Observable
class WeekViewModel {
    private var calendar: Calendar = .current
    var user: User = .init()
    var day: Day = .init(timestamp: Date())
    var events: [Event] = []
    var todos: [Todo] = []

    private let datasource: SwiftDataService

    init(datasource: SwiftDataService) {
        self.datasource = datasource
        day = datasource.fetchDay(date: Date())
        user = datasource.fetchUser()
        events = fetchSortedEvents(activeCalendars: user.activeCalendars)
        todos = fetchSortedTodos()
    }

    func fetchSortedEvents(activeCalendars _: [ActiveCalendar]) -> [Event] {
        let activeCalendars = user.activeCalendars

        if activeCalendars.isEmpty {
            return []
        }

        let startOfDay = calendar.startOfDay(for: day.timestamp)

        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            fatalError("Failed to calculate end of day")
        }

        let predicate = getEventStore().predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: datasource.fetchActiveCalendars(activeCalendars: activeCalendars)
        )

        var ekEvents: [Event] = []
        for event in getEventStore().events(matching: predicate) {
            let newEvent = Event(eventIdentifier: event.eventIdentifier, start: event.startDate, end: event.endDate, title: event.title)
            ekEvents.append(newEvent)
        }

        events = ekEvents
        return events.sorted { $0.start < $1.start }
    }

    func fetchSortedTodos() -> [Todo] {
        return day.todos.sorted { $0.timestamp < $1.timestamp }
    }

    func stepDayBy(days: Int) {
        let newDate = calendar.date(byAdding: .day, value: days, to: day.timestamp) ?? day.timestamp.advanced(by: TimeInterval(86400 * days))
        day = datasource.fetchDay(date: newDate)
        events = fetchSortedEvents(activeCalendars: user.activeCalendars)
        todos = fetchSortedTodos()
        save()
    }

    func updateDayTo(date: Date) {
        day = datasource.fetchDay(date: date)
        events = fetchSortedEvents(activeCalendars: user.activeCalendars)
        todos = fetchSortedTodos()
        save()
    }

    func newTodo() -> Todo {
        let todo = datasource.createTodo(day: day)
        todos.append(todo)
        save()
        return todo
    }

    func deleteTodo(todo: Todo) {
        datasource.deleteTodo(day: day, todo: todo)
        save()
    }

    func newEvent(start: Date, end: Date, title: String) -> Event? {
        if let event = datasource.createEventInCalendar(title: title, start:
            start, end: end)
        {
            events.append(event)
            save()
            return event
        }
        return nil
    }

    func deleteEventInCalendar(event: Event) {
        datasource.deleteEventInCalendar(day: day, event: event)
        save()
    }

    func updateEventInCalendar(event: Event) {
        datasource.updateEventInCalendar(day: day, event: event)
        refresh()
        save()
    }

    func refresh() {
        updateDayTo(date: day.timestamp)
    }

    func getEventStore() -> EKEventStore {
        return datasource.eventStore
    }

    func save() {
        datasource.save()
    }
}
