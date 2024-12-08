import EventKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(SharedState.self) private var sharedState
    @State private var isEditing: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                isEditing = true
                sharedState.activateSheet(.editSettings)
            } label: {
                Image("logo")
                    .resizable() // Make the image resizable if needed
                    .scaledToFit() // Adjust the content mode
                    .frame(width: 15, height: 15) // Set desired frame
            }
            .sheet(isPresented: $isEditing, onDismiss: { sharedState.activateSheet(.main) }) {
                SettingsSheet()
                    .presentationBackground {
                        Color.black.ignoresSafeArea()
                    }
            }
            Spacer()
        }
        .padding()
        .frame(maxHeight: 15)
    }
}

struct SettingsSheet: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(SharedState.self) private var sharedState
    @State private var calendars: [EKCalendar] = []

    var body: some View {
        VStack {
            DottedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.bottom, 8) // Optional padding between line and content

            HStack {
                Text("settings;")
                    .font(.custom("GohuFont11NFM", size: 24))
                Spacer()
            }
            .padding(.horizontal)

            ScrollView {
                Group {
                    VStack {
                        CompletedEventsToggle()
                        DoneTodosToggle()
                    }
                }
                .padding()

                Group {
                    HStack {
                        Text("available_calendars;")
                            .font(.custom("GohuFont11NFM", size: 24))

                        Spacer()
                    }.padding(.horizontal)

                    if userViewModel.user.activeCalendars.isEmpty {
                        GroupBox {
                            Text("Without a calendar selected, no events will be shown!")
                        }
                        .padding()
                    }

                    VStack {
                        ForEach(calendars, id: \.calendarIdentifier) { calendar in
                            CalendarToggle(calendar: calendar)
                        }
                    }.padding()
                    Spacer()
                }
            }
        }
        .padding()
        .presentationDetents([.fraction(0.55)])
        .onAppear(perform: initCalendarSettings)
    }

    func initCalendarSettings() {
        calendars = userViewModel.getAvailableCalendars()
    }
}

struct CalendarToggle: View {
    @State var calendar: EKCalendar
    @State var isOn: Bool = false
    @Environment(UserViewModel.self) private var userViewModel

    var body: some View {
        Toggle(calendar.title, isOn: $isOn).onChange(of: isOn) {
            if isOn {
                userViewModel.activateCalendar(calendar: calendar)
            } else {
                userViewModel.deleteCalendar(calendar: calendar)
            }
        }.onAppear(perform: checkToggle)
    }

    func checkToggle() {
        isOn = userViewModel.hasCalendar(calendar: calendar)
    }
}

struct CompletedEventsToggle: View {
    @State var isOn: Bool = false
    @Environment(UserViewModel.self) private var userViewModel

    var body: some View {
        Toggle("show_past_events", isOn: $isOn).onChange(of: isOn) {
            if isOn {
                userViewModel.showCompletedEvents()
            } else {
                userViewModel.hideCompletedEvents()
            }
        }.onAppear(perform: checkToggle)
    }

    func checkToggle() {
        isOn = userViewModel.user.showCompleted
    }
}

struct DoneTodosToggle: View {
    @State var isOn: Bool = false
    @Environment(UserViewModel.self) private var userViewModel

    var body: some View {
        Toggle("show_done_todos", isOn: $isOn).onChange(of: isOn) {
            if isOn {
                userViewModel.showDoneTodos()
            } else {
                userViewModel.hideDoneTodos()
            }
        }.onAppear(perform: checkToggle)
    }

    func checkToggle() {
        isOn = userViewModel.user.showDone
    }
}

@MainActor
@Observable
class UserViewModel {
    var user: User = .init()

    private let datasource: SwiftDataService
    init(datasource: SwiftDataService) {
        self.datasource = datasource
        user = datasource.fetchUser()
    }

    func hideCompletedEvents() {
        user.showCompleted = false
        save()
    }

    func showCompletedEvents() {
        user.showCompleted = true
        save()
    }

    func hideDoneTodos() {
        user.showDone = false
        save()
    }

    func showDoneTodos() {
        user.showDone = true
        save()
    }

    func getAvailableCalendars() -> [EKCalendar] {
        return datasource.fetchAvailableEventCalendars()
    }

    func activateCalendar(calendar: EKCalendar) {
        if findCalendarIndex(calendar: calendar) == nil {
            let activeCalendar = ActiveCalendar(calendar: calendar)
            user.activeCalendars.append(activeCalendar)
            save()
        }
    }

    func deleteCalendar(calendar: EKCalendar) {
        if let index = findCalendarIndex(calendar: calendar) {
            user.activeCalendars.remove(at: index)
            save()
        }
    }

    func findCalendarIndex(calendar: EKCalendar) -> Int? {
        return user.activeCalendars.firstIndex(where: { ($0.calendarIdentifier == calendar.calendarIdentifier) || ($0.title == calendar.title && $0.sourceTitle == calendar.source.title) })
    }

    func hasCalendar(calendar: EKCalendar) -> Bool {
        return user.activeCalendars.contains(where: { ($0.calendarIdentifier == calendar.calendarIdentifier) || ($0.title == calendar.title && $0.sourceTitle == calendar.source.title) })
    }

    func save() {
        datasource.save()
    }
}
