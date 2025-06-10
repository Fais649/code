import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.dismiss) var dismiss
    @Query var eventCalendars: [EventCalendar]
    @State private var showColorPickerSheet: Bool = false
    @Query(sort: \Ritual.position) var rituals: [Ritual]

    var groupedCalendars: [String: [EventCalendar]] {
        let groups = Dictionary(grouping: eventCalendars) { $0.sourceTitle }
        var sortedGroups: [String: [EventCalendar]] = [:]
        for source in groups.keys.sorted() {
            sortedGroups[source] = groups[source]!.sorted { $0.title < $1.title }
        }
        return sortedGroups
    }

    var activeGroupedCalendars: [String: [EventCalendar]] {
        groupedCalendars.filter({
            !$0.value.filter({ $0.isActive }).isEmpty
        })
    }

    var inactiveGroupedCalendars: [String: [EventCalendar]] {
        groupedCalendars.filter({
            !$0.value.filter({ !$0.isActive })
                .isEmpty
        })
    }

    var body: some View {
        List {
            Section(header: Text("About me")) {
                Text("Faisal Alalaiwat")
                Text("fais649@proton.me")
                Text("github: fais649")
                Text("Free Palestine")
            }

            Button("Default Color") {
                showColorPickerSheet.toggle()
            }.sheet(isPresented: $showColorPickerSheet) {
                ColorPickerSheet(selectedColor: Default.color) { newColor in
                    Default.setColor(newColor)
                    showColorPickerSheet = false
                }
            }

            Section(
                header: HStack {
                    Text("Rituals")
                    Spacer()
                    Button {
                        let newRitual = Ritual(position: rituals.count)
                        modelContext.insert(newRitual)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            ) {
                RitualStack(rituals: rituals)
            }

            if !activeGroupedCalendars.isEmpty {
                Section(
                    header: Text("Active Calendars"),
                    footer: Text(
                        "Deactivating a calendar will delete all moments associated with that calendar from wisp_r. Note: this will not delete those events from your system calendar. It only deletes the moments you've created in wisp_r. Your system calendar will remain exactly as is."
                    )
                ) {
                    ForEach(
                        activeGroupedCalendars
                            .sorted(by: { $0.key < $1.key }), id: \.key
                    ) {
                        sourceTitle, eventCalendars in
                        DisclosureGroup {
                            ForEach(
                                eventCalendars.filter({
                                    !Default.isDefault(eventCalendar: $0)
                                }).sorted(by: { $0.title < $1.title })
                            ) { eventCalendar in
                                Button {
                                    EKCalendarService.deactivate(eventCalendar, in: modelContext)
                                } label: {
                                    HStack {
                                        Image(
                                            systemName: eventCalendar.isActive
                                                ? "square.fill" : "square.dotted")
                                        Text(eventCalendar.title)
                                    }
                                }
                            }
                        } label: {
                            Text(sourceTitle)
                        }
                    }
                }
            }

            if !inactiveGroupedCalendars.isEmpty {
                Section(
                    header: Text("Inactive Calendars"),

                    footer: Text(
                        "Wisp_r will automatically import any events in an activated calendar as moments. Any changes you make to imported events (i.e. changing the event name, timings, or location) will update the event in your system calendar as well. Any changes to imported events outside of wisp_r, or any events added to the system calendar from outside of wisp_r, will also be kept in sync if a calendar is active."
                    )
                ) {
                    ForEach(
                        inactiveGroupedCalendars
                            .sorted(by: { $0.key < $1.key }), id: \.key
                    ) {
                        sourceTitle, eventCalendars in
                        DisclosureGroup {
                            ForEach(
                                eventCalendars.filter({
                                    !Default.isDefault(eventCalendar: $0)
                                }).sorted(by: { $0.title < $1.title })
                            ) { eventCalendar in
                                Button {
                                    EKCalendarService.activate(eventCalendar, in: modelContext)
                                } label: {
                                    HStack {
                                        Image(
                                            systemName: eventCalendar.isActive
                                                ? "square.fill" : "square.dotted")
                                        Text(eventCalendar.title)
                                    }
                                }
                            }
                        } label: {
                            Text(sourceTitle)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Text("Settings")
            }

            ToolbarItemGroup(placement: .bottomBar) {
                BackButton()

                Spacer()
            }
        }
    }
}
