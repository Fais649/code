import SwiftData
import SwiftUI

struct DayVStack: View {
    @Environment(\.modelContext) var modelContext
    @Environment(BroadcasterService.self) private var broadcaster

    let day: Day
    @State private var sheetMoment: Moment?
    @State private var visible: Bool = false

    @State private var showDatePickerSheet: Bool = false
    @State private var showDaySheet: Bool = false
    @State private var onSelectDate: ((_ newDate: Date) -> Void)?
    @State private var note: String = ""

    @FocusState private var focused: Bool

    @Namespace var namespace
    func foregroundColor(_ ritualRecord: RitualRecord) -> Color {
        ritualRecord.counter.isCompleted ? Default.backgroundColor : Default.foregroundColor
    }

    func backgroundColor(_ ritualRecord: RitualRecord) -> Color {
        ritualRecord.counter.isCompleted ? Default.foregroundColor : Default.backgroundColor
    }

    var body: some View {
        VStack {
            List {
                Section{
                    MomentStack(
                    sheetMoment: $sheetMoment,
                    moments: day.moments.filter {$0.id != sheetMoment?.id},
                    momentType: .all
                ) 
                }
                    .transition(.opacity)
            }
            .scrollContentBackground(.hidden)


                HStack(alignment: .top, spacing: Spacing.ss) {
                    if !focused {

                HStack(alignment: .center){ Rectangle()
                    .fill(Default.foregroundColor)
                    .frame(width: 1)
                    .opacity(day.date.isPastDay ? 0.4 : 1)

                        DateTitle(date: day.date) }
                    }

                    Spacer()

                    RitualRecordStack(
                        interactive: day.date.isToday, ritualRecords: day.ritualRecords)
                }
            .frame(height: Spacing.l)
            .padding(.bottom, Spacing.l)
            .padding(.horizontal, Spacing.m)
            .overlay(alignment: .bottomTrailing) {
                if focused {
                    Button {
                        focused = false
                    } label: {
                        Image(systemName: "chevron.down")
                    }

                }
            }
            .padding(Spacing.s)
        }
        .animation(.smooth, value: sheetMoment?.id)
        .onScrollVisibilityChange { new in
            visible = new
        }
        .containerRelativeFrame(.horizontal)
        .onChange(of: broadcaster.isEventSet) {
            guard visible, let event = broadcaster.receive() else { return }
            switch event {
            case .createNewEventOnActiveDay:
                let m = Moment(day: day, position: day.moments.count)
                modelContext.insert(m)
                try? modelContext.save()
                sheetMoment = m
            case let .showDatePickerSheet(onSelectDate):
                showDatePickerSheet.toggle()
                self.onSelectDate = onSelectDate
            }
        }
        .sheet(item: $sheetMoment) { moment in
            MomentSheet(moment: moment)
        }
        .sheet(isPresented: $showDaySheet) {
            DaySheet()
        }
        .sheet(isPresented: $showDatePickerSheet) {
            DatePickerSheet(selectedDate: day.date) { newDate in
                showDatePickerSheet = false
                if let onSelectDate {
                    onSelectDate(newDate)
                }
            }

        }
    }
}
