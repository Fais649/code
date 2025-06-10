import SwiftData
import SwiftUI

struct DualDatePickerSheetButton: View {
    @Environment(\.modelContext) var modelContext
    let moment: Moment
    @State private var showEventKitUI: Bool = false
    @State private var showDatePicker: Bool = false

    var startDate: Date {
        if let event = moment.event {
            return event.startDate
        }

        if var date = moment.day?.date {
            date.setTime(from: Date())
            return date
        } else {
            return Date()
        }
    }

    var endDate: Date {
        if let event = moment.event {
            return event.endDate
        }

        if var date = moment.day?.date {
            date.setTime(from: Date().advanced(by: 3600))
            return date
        } else {
            return Date().advanced(by: 3600)
        }
    }

    var body: some View {
        Menu {
            if moment.isEvent {
                Button("Remove from calendar", systemImage: "clock.badge.xmark") {
                    guard let event = moment.event else { return }
                    EKCalendarService.delete(event, in: modelContext)
                }
            } else {
                Button("Select a day", systemImage: "diamond.fill") {
                    showDatePicker.toggle()
                }
            }

            Button(
                moment.isEvent ? "Edit in calendar" : "Add to calendar",
                systemImage: moment.isEvent ? "clock.fill" : "clock"
            ) {
                showEventKitUI.toggle()
            }
        } label: {
            Image(systemName: "diamond.fill")
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: startDate) { date in
                MomentStore.move(moment, to: date, in: modelContext)
                showDatePicker = false
            }
        }
        .sheet(isPresented: $showEventKitUI) {
            CalendarEventSheet(
                startDate: startDate,
                endDate: endDate,
                eventTitle: moment.text
            ) { ekEvent in
                MomentStore.attachEvent(ekEvent: ekEvent, to: moment, in: modelContext)
            }
        }
    }
}
